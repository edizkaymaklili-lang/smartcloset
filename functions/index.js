const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const axios = require('axios');

/**
 * getOutfitRecommendation — Firebase Cloud Function
 *
 * Called from Flutter via FirebaseFunctions.instance.httpsCallable(...)
 *
 * Input (data):
 *   temperature: number (°C)
 *   feelsLike: number
 *   humidity: number (%)
 *   windSpeed: number (km/h)
 *   precipitation: number (mm)
 *   weatherDescription: string
 *   city: string
 *   stylePreference: string (classic | sporty | bohemian | elegant)
 *   wardrobeItems: Array<{ id, name, category, color, seasons, occasions, weatherSuitability }>
 *
 * Output (JSON):
 *   { occasions: { office: {...}, casual: {...}, night: {...} }, smartTips: [...] }
 */
exports.getOutfitRecommendation = onCall(
  { secrets: ['GEMINI_API_KEY'], timeoutSeconds: 60 },
  async (request) => {
    const data = request.data;

    // Validate input
    if (!data.city || data.temperature === undefined) {
      throw new HttpsError('invalid-argument', 'Missing required weather data');
    }

    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      throw new HttpsError('failed-precondition', 'Gemini API key not configured');
    }

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({
      model: 'gemini-1.5-flash-latest',
      generationConfig: {
        responseMimeType: 'application/json',
        temperature: 0.7,
      },
    });

    // Build wardrobe context
    const wardrobeText =
      data.wardrobeItems && data.wardrobeItems.length > 0
        ? data.wardrobeItems
            .map(
              (item) =>
                `- [${item.id}] ${item.name} (${item.category}, ${item.color}, ` +
                `seasons: ${item.seasons?.join(',')}, occasions: ${item.occasions?.join(',')}, ` +
                `weather: ${item.weatherSuitability?.join(',')})`
            )
            .join('\n')
        : 'No wardrobe items available — suggest generic pieces.';

    const prompt = `You are an expert fashion stylist AI assistant for women. Generate personalized outfit recommendations based on the following context.

WEATHER TODAY:
- Temperature: ${data.temperature}°C (feels like ${data.feelsLike || data.temperature}°C)
- Condition: ${data.weatherDescription}
- Humidity: ${data.humidity}%
- Wind speed: ${data.windSpeed} km/h
- Precipitation: ${data.precipitation || 0} mm

LOCATION: ${data.city}
STYLE PREFERENCE: ${data.stylePreference}

PERSONALIZATION PROFILE:
- Body Type: ${data.bodyType || 'Not specified'}
- Height: ${data.heightRange || 'Not specified'}
- Work Type: ${data.workType || 'Not specified'}
- Hobbies/Activities: ${data.hobbies && data.hobbies.length > 0 ? data.hobbies.join(', ') : 'Not specified'}
- Color Season: ${data.colorSeason || 'Not specified'}
- Best Colors: ${data.bestColors && data.bestColors.length > 0 ? data.bestColors.join(', ') : 'Not specified'}
- Colors to Avoid: ${data.avoidColors && data.avoidColors.length > 0 ? data.avoidColors.join(', ') : 'Not specified'}
- Recommended Styles for Body Type: ${data.bodyTypeStyles && data.bodyTypeStyles.length > 0 ? data.bodyTypeStyles.join(', ') : 'Not specified'}

USER'S WARDROBE:
${wardrobeText}

IMPORTANT PERSONALIZATION RULES:
- If body type is specified, recommend cuts and silhouettes that flatter that body type.
- If color season is specified, prioritize the best colors and avoid the listed colors.
- If height range is specified, adjust proportions accordingly (e.g., petite: high waist, vertical lines; tall: wide-leg pants, long dresses).
- If work type is specified, adapt the "office" occasion to match their work environment.
- If hobbies include active sports, add a practical tip for their activity outfit.
- All recommendations should be in Turkish language.

TASK: Generate outfit recommendations for THREE occasions:
1. office — Work Week (professional, polished)
2. casual — Daily (comfortable, practical)
3. night — Special Night (elegant, statement)

For EACH occasion, provide:
- items: array of 2-4 clothing pieces. Each item:
  - category: one of [tops, bottoms, outerwear, shoes, accessories, dresses]
  - description: specific item description
  - wardrobeItemId: the [id] from wardrobe if a matching item exists, otherwise null
- makeup:
  - foundation: foundation recommendation
  - lips: lip color/product recommendation
  - eyes: eye makeup recommendation
  - tip: one makeup tip
- accessories: array of exactly 4 accessory/jewelry suggestions (strings)
- smartTip: one occasion-specific styling tip

Also provide smartTips: array of 2-3 general tips about today's weather/dressing.

Respond ONLY with valid JSON in this exact structure:
{
  "occasions": {
    "office": {
      "items": [{"category": "...", "description": "...", "wardrobeItemId": null}],
      "makeup": {"foundation": "...", "lips": "...", "eyes": "...", "tip": "..."},
      "accessories": ["...", "...", "...", "..."],
      "smartTip": "..."
    },
    "casual": { ... },
    "night": { ... }
  },
  "smartTips": ["...", "..."]
}`;

    try {
      const result = await model.generateContent(prompt);
      const text = result.response.text();

      // Parse and validate JSON
      const parsed = JSON.parse(text);
      if (!parsed.occasions || !parsed.occasions.office) {
        throw new Error('Invalid response structure from Gemini');
      }

      return parsed;
    } catch (err) {
      console.error('Gemini error:', err);
      throw new HttpsError('internal', `AI generation failed: ${err.message}`);
    }
  }
);

/**
 * fashnTryOn — Virtual Try-On Cloud Function
 *
 * Called from Flutter via FirebaseFunctions.instance.httpsCallable(...)
 *
 * Input (data):
 *   modelImage: string (base64 encoded image of user's model photo)
 *   garmentImage: string (URL or base64 encoded garment image)
 *   category: string ('tops' | 'bottoms' | 'one-pieces')
 *
 * Output (JSON):
 *   { output: [url1, url2, ...] } — array of result image URLs
 */
exports.fashnTryOn = onCall(
  { secrets: ['FASHN_API_KEY'], timeoutSeconds: 120 },
  async (request) => {
    const { modelImage, garmentImage, category } = request.data;

    // Validate input
    if (!modelImage || !garmentImage || !category) {
      throw new HttpsError('invalid-argument', 'Missing required fields: modelImage, garmentImage, category');
    }

    const apiKey = process.env.FASHN_API_KEY;
    if (!apiKey) {
      throw new HttpsError('failed-precondition', 'Fashn API key not configured');
    }

    const headers = {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    };

    // Step 1: Submit the try-on job
    let jobId;
    try {
      const runResponse = await axios.post(
        'https://api.fashn.ai/v1/run',
        {
          model_image: modelImage,
          garment_image: garmentImage,
          category: category,
        },
        { headers }
      );
      jobId = runResponse.data.id;
      console.log(`Fashn try-on job submitted: ${jobId}`);
    } catch (err) {
      console.error('Fashn submit error:', err.response?.data || err.message);
      throw new HttpsError('internal', `Fashn submit failed: ${err.response?.data?.message || err.message}`);
    }

    // Step 2: Poll for completion (max 100 seconds, 5s intervals = 20 attempts)
    const maxAttempts = 20;
    for (let i = 0; i < maxAttempts; i++) {
      // Wait 5 seconds before checking
      await new Promise((resolve) => setTimeout(resolve, 5000));

      try {
        const statusResponse = await axios.get(
          `https://api.fashn.ai/v1/status/${jobId}`,
          { headers }
        );
        const { status, output, error } = statusResponse.data;

        console.log(`Fashn job ${jobId} status: ${status} (attempt ${i + 1}/${maxAttempts})`);

        if (status === 'completed' && output && output.length > 0) {
          console.log(`Fashn job ${jobId} completed successfully`);
          return { output }; // Return array of image URLs
        }

        if (status === 'failed') {
          throw new HttpsError('internal', `Try-on failed: ${error || 'Unknown error'}`);
        }

        // Status is 'processing' or 'queued' — continue polling
      } catch (err) {
        if (err instanceof HttpsError) throw err; // Re-throw our own errors
        console.error('Fashn status check error:', err.message);
        // Continue polling even if one status check fails
      }
    }

    // Timeout after 100 seconds
    throw new HttpsError('deadline-exceeded', `Try-on timed out after ${maxAttempts * 5} seconds`);
  }
);
