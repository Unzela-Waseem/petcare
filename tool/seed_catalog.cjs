const projectId = "pawfectcare-unzela-2026";

const images = {
  Food: "https://images.unsplash.com/photo-1589924691995-400dc9ecc119?auto=format&fit=crop&w=900&q=80",
  Grooming: "https://images.unsplash.com/photo-1516734212186-a967f81ad0d7?auto=format&fit=crop&w=900&q=80",
  Toys: "https://images.unsplash.com/photo-1591946614720-90a587da4a36?auto=format&fit=crop&w=900&q=80",
  Health: "https://images.unsplash.com/photo-1576201836106-db1758fd1c97?auto=format&fit=crop&w=900&q=80",
};

const products = [
  ["catalog-salmon-bites", "Salmon Training Bites", "Small protein-rich rewards for positive training.", 12, "Food", "salmon+pet+training+treats"],
  ["catalog-puppy-formula", "Puppy Growth Formula", "Complete nutrition formulated for growing puppies.", 31, "Food", "puppy+growth+food"],
  ["catalog-indoor-cat-food", "Indoor Cat Nutrition", "Balanced food for adult indoor cats and hairball care.", 27, "Food", "indoor+adult+cat+food"],
  ["catalog-senior-food", "Senior Pet Support Food", "Easy-to-digest nutrition for older pets.", 35, "Food", "senior+pet+food"],
  ["catalog-sensitive-shampoo", "Sensitive Skin Shampoo", "Mild fragrance-free wash for delicate coats.", 16, "Grooming", "sensitive+skin+pet+shampoo"],
  ["catalog-deshedding-brush", "Deshedding Brush", "Rounded grooming teeth help remove loose undercoat.", 21, "Grooming", "pet+deshedding+brush"],
  ["catalog-paw-balm", "Paw & Nose Balm", "Protective moisturizer for dry paws and noses.", 11, "Grooming", "pet+paw+nose+balm"],
  ["catalog-nail-care", "Safe Nail Care Set", "Clippers, file, and styptic powder for careful trims.", 19, "Grooming", "pet+nail+care+kit"],
  ["catalog-rope-tug", "Cotton Rope Tug", "Durable interactive tug toy for active dogs.", 10, "Toys", "cotton+rope+dog+toy"],
  ["catalog-feather-wand", "Feather Chase Wand", "Interactive movement toy for supervised cat play.", 9, "Toys", "cat+feather+wand+toy"],
  ["catalog-squeaky-ball", "Squeaky Ball Set", "Three bright fetch balls for supervised exercise.", 14, "Toys", "squeaky+pet+ball+set"],
  ["catalog-treat-dispenser", "Treat Dispensing Ball", "Slow-release enrichment toy for meals and rewards.", 17, "Toys", "pet+treat+dispensing+ball"],
  ["catalog-thermometer", "Digital Pet Thermometer", "Quick temperature checks with a protective case.", 15, "Health", "digital+pet+thermometer"],
  ["catalog-dental-care", "Dental Care Pack", "Pet toothbrush, finger brush, and pet-safe toothpaste.", 20, "Health", "pet+dental+care+kit"],
  ["catalog-joint-support", "Joint Support Chews", "Daily mobility supplement; ask your vet before use.", 26, "Health", "pet+joint+support+chews"],
  ["catalog-tick-tool", "Tick Removal Tool", "Compact hook set for safer tick removal.", 8, "Health", "pet+tick+removal+tool"],
].map(([id, name, description, price, category, search]) => ({
  id,
  name,
  description,
  price,
  category,
  imageUrl: images[category],
  purchaseUrl: `https://www.google.com/search?q=${search}`,
  active: true,
}));

const blogImages = {
  Training: "https://images.unsplash.com/photo-1587300003388-59208cc962cb?auto=format&fit=crop&w=1000&q=80",
  Nutrition: "https://images.unsplash.com/photo-1601758228041-f3b2795255f1?auto=format&fit=crop&w=1000&q=80",
  "First Aid": "https://images.unsplash.com/photo-1628009368231-7bb7cfcb0def?auto=format&fit=crop&w=1000&q=80",
  "Pet Care": "https://images.unsplash.com/photo-1450778869180-41d0601e046e?auto=format&fit=crop&w=1000&q=80",
};

const blogs = [
  ["catalog-positive-reinforcement", "Positive reinforcement basics", "Training", "Teach useful behavior without fear or force.", "Reward the behavior you want immediately with food, play, or praise. Keep sessions short, use clear cues, and avoid punishment that can increase fear or confusion.", 19],
  ["catalog-loose-leash", "Loose-leash walking made simple", "Training", "Build calmer walks one small step at a time.", "Begin in a quiet place and reward your dog for staying near you. Stop when the leash becomes tight, then continue when attention returns and the leash relaxes.", 18],
  ["catalog-carrier-training", "Comfortable carrier training", "Training", "Help cats and small pets see the carrier as a safe space.", "Leave the carrier open with soft bedding and treats inside. Feed nearby, reward voluntary entry, and practice closing the door briefly before attempting travel.", 17],
  ["catalog-food-labels", "How to read pet-food labels", "Nutrition", "Understand life-stage claims, ingredients, and feeding guides.", "Start with the intended species and life stage, then review the complete-and-balanced statement. Treat package portions as a starting point and adjust only with professional guidance.", 15],
  ["catalog-healthy-treats", "Healthy treats and portions", "Nutrition", "Keep rewards useful without unbalancing the daily diet.", "Use tiny treats and include them in the daily calorie plan. Choose pet-safe ingredients, avoid toxic human foods, and use part of the regular meal for training when appropriate.", 14],
  ["catalog-hydration", "Hydration and warning signs", "Nutrition", "Support healthy water intake and recognize concerning changes.", "Provide clean water in accessible bowls and monitor normal drinking patterns. Sudden increases, refusal to drink, repeated vomiting, or marked weakness need veterinary advice.", 13],
  ["catalog-emergency-signs", "Recognizing a pet emergency", "First Aid", "Know which warning signs need urgent professional care.", "Difficulty breathing, collapse, uncontrolled bleeding, seizures, severe pain, poisoning, or repeated unproductive retching are emergencies. Call a veterinarian while arranging safe transport.", 11],
  ["catalog-wound-care", "Safe first response to a wound", "First Aid", "Protect yourself, control bleeding, and seek help.", "Approach carefully because pain can change behavior. Apply gentle pressure with clean gauze, prevent licking, and contact a clinic; never use human pain medicines.", 10],
  ["catalog-heatstroke", "Heatstroke prevention and response", "First Aid", "Keep pets safe during hot weather and travel.", "Avoid hot cars and midday exercise, offer shade and water, and watch for heavy panting or weakness. Move an overheated pet to a cooler area and seek emergency veterinary care.", 9],
  ["catalog-coat-skin", "A healthy coat and skin routine", "Pet Care", "Use regular checks to catch irritation and parasites early.", "Brush according to coat type and look for redness, flakes, lumps, odor, or parasites. Use only species-safe products and ask a veterinarian about persistent itching.", 7],
  ["catalog-dental-hygiene", "Daily dental hygiene for pets", "Pet Care", "Protect teeth and gums with gradual home care.", "Introduce pet-safe toothpaste slowly and reward calm handling. Never use human toothpaste, and arrange a veterinary dental assessment for pain, bleeding, or strong odor.", 6],
  ["catalog-senior-wellness", "Supporting a senior pet", "Pet Care", "Adapt routines as mobility, senses, and health needs change.", "Provide non-slip surfaces, comfortable bedding, easy access to essentials, and gentle activity. Track weight and behavior changes and keep regular veterinary wellness visits.", 5],
].map(([id, title, category, summary, content, day]) => ({
  id,
  title,
  category,
  summary,
  content,
  imageUrl: blogImages[category],
  published: true,
  publishedAt: new Date(Date.UTC(2026, 7, day, 9)),
}));

function firestoreValue(value) {
  if (value instanceof Date) return { timestampValue: value.toISOString() };
  if (typeof value === "boolean") return { booleanValue: value };
  if (typeof value === "number") return { doubleValue: value };
  return { stringValue: String(value) };
}

async function writeDocument(accessToken, collection, document) {
  const { id, ...data } = document;
  const now = new Date();
  const fields = Object.fromEntries(
    Object.entries({ ...data, createdAt: now, updatedAt: now }).map(
      ([key, value]) => [key, firestoreValue(value)],
    ),
  );
  const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/${collection}/${id}`;
  const response = await fetch(url, {
    method: "PATCH",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ fields }),
  });
  if (!response.ok) {
    throw new Error(`${collection}/${id}: ${response.status} ${await response.text()}`);
  }
}

async function seedCatalog({ accessToken }) {
  if (!accessToken) throw new Error("A Google OAuth access token is required.");
  for (const product of products) {
    await writeDocument(accessToken, "products", product);
  }
  for (const blog of blogs) {
    await writeDocument(accessToken, "blogs", blog);
  }
  return { products: products.length, blogs: blogs.length };
}

module.exports = { seedCatalog, products, blogs };
