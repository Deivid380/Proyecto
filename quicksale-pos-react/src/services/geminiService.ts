import { GoogleGenAI, Chat } from "@google/genai";
import { ImageSize } from '../types';

// Instance for standard chat (uses env key)
const getStandardClient = () => {
  return new GoogleGenAI({ apiKey: process.env.API_KEY });
};

// Instance for high-end models (requires user selected key)
const getUserKeyClient = async () => {
  // We create a new instance to ensure we pick up the latest state/key context
  // if it changes after the user selects a key via the UI.
  return new GoogleGenAI({ apiKey: process.env.API_KEY });
};

export const createChatSession = async (): Promise<Chat> => {
  const ai = getStandardClient();
  return ai.chats.create({
    model: 'gemini-3-pro-preview',
    config: {
      systemInstruction: "Eres un experto asistente de negocios para un pequeño comercio (tienda, ferretería, kiosco). Ayuda al dueño a analizar ventas, dar consejos de marketing, gestión de inventario y optimización de ganancias. Responde de manera concisa, amable y profesional en español.",
    },
  });
};

export const generateProductImage = async (
  prompt: string,
  size: ImageSize
): Promise<string | null> => {
  try {
    const ai = await getUserKeyClient();
    const result = await ai.images.generate({
        model: "gemini-3-pro-image",
        prompt: `Fotografía de producto profesional, fondo blanco, alta calidad: ${prompt}`,
        count: 1,
        size: size,
        quality: "hd",
    });

    const image = result.images[0];
    return image.b64;

  } catch (error) {
    console.error("Error generating image:", error);
    throw error;
  }
};
