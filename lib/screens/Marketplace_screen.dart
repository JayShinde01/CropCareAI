// lib/screens/marketplace_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({Key? key}) : super(key: key);

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  String selectedCategory = "All";
  String searchText = "";

  // products (same data you provided)
  final List<Map<String, dynamic>> allProducts = [
    {
      "name": "Hybrid Wheat Seeds Premium",
      "description": "High-yield hybrid seeds suitable for all weather conditions.",
      "category": "Seeds",
      "price": 499,
      "image":
          "https://images.jdmagicbox.com/quickquotes/images_main/hybrid-wheat-seeds-for-agriculture-2223020736-8625zs45.jpg",
      "link": "https://www.amazon.in/s?k=hybrid+wheat+seeds",
    },
     {
    "name": "Organic Wheat Seeds Grade A",
    "description": "Chemical-free seeds for natural farming and high protein wheat.",
    "category": "Seeds",
    "price": 550,
    "image": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ2F3DsX6ILDAdn6mre_0xEOMbsZzWExFRslA&s",
    "link": "https://www.amazon.in/s?k=organic+wheat+seeds",
  },
  {
    "name": "Drought Resistant Wheat Seeds",
    "description": "Designed for low-water soil with stable growth.",
    "category": "Seeds",
    "image":"https://m.media-amazon.com/images/I/61hSpDZYjYL.jpg",
    "price": 600,

    "link": "https://www.amazon.in/s?k=wheat+seeds",
  },
  {
    "name": "Rust-Proof Wheat Seeds",
    "description": "Strong protection against rust and crop infections.",
    "category": "Seeds",
    "price": 650,
    "image": "https://m.media-amazon.com/images/I/61qRGSp+p1L._AC_UL480_FMwebp_QL65_.jpg",
    "link": "https://www.amazon.in/s?k=wheat+seeds",
  },
  {
    "name": "Export Quality Wheat Seeds",
    "description": "Superior quality seeds with maximum productivity.",
    "category": "Seeds",
    "price": 700,
    "image": "https://m.media-amazon.com/images/I/817V8yCaGuL._AC_UL480_FMwebp_QL65_.jpg",
    "link": "https://www.amazon.in/s?k=wheat+export+quality+seeds",
  },
  {
    "name": "Ultra Yield Wheat Seeds",
    "description": "Perfect for farmers targeting commercial yields.",
    "category": "Seeds",
    "price": 720,
    "image": "https://m.media-amazon.com/images/I/91SLLqXhB7L._AC_UL480_FMwebp_QL65_.jpg",
    "link": "https://www.amazon.in/s?k=wheat+seeds+high+yield",
  },
 
  // 🌱 10 FERTILIZERS
  {
    "name": "Nitrogen Fertilizer",
    "description": "Boosts leaf growth and plant health.",
    "category": "Fertilizer",
    "price": 350,
    "image": "https://m.media-amazon.com/images/I/71AYgeiZuiL._AC_SX416_CB1169409_QL70_.jpg",
    "link": "https://www.amazon.in/s?k=nitrogen+fertilizer",
  },
  {
    "name": "NPK 19:19:19 Fertilizer",
    "description": "Balanced nutrients for overall growth.",
    "category": "Fertilizer",
    "price": 450,
    "image": "https://m.media-amazon.com/images/I/71KdSj45HqL._AC_UL480_FMwebp_QL65_.jpg",
    "link": "https://www.amazon.in/s?k=NPK+19:19:19",
  },
  {
    "name": "Organic Compost",
    "description": "Improves soil quality naturally.",
    "category": "Fertilizer",
    "price": 299,
    "image": "https://m.media-amazon.com/images/I/81pP5DYpyzL._AC_SX416_CB1169409_QL70_.jpg",
    "link": "https://www.amazon.in/s?k=organic+compost",
  },
  {
    "name": "Vermicompost Fertilizer",
    "description": "Earthworm compost for nutrient rich soil.",
    "category": "Fertilizer",
    "price": 250,
    "image": "https://m.media-amazon.com/images/I/51oLtc-MeFL._SX522_.jpg",
    "link": "https://www.amazon.in/s?k=vermicompost",
  },
  {
    "name": "Urea Fertilizer Premium",
    "description": "High-quality urea for strong plant growth.",
    "category": "Fertilizer",
    "price": 320,
    "image": "https://encrypted-tbn0.gstatic.com/shopping?q=tbn:ANd9GcRNCboCRZTuOf1DK3XYrcB3BhP8KsMjlIP4NhLaew8PsZ2XcNzTKkgDGbmFlgBuBZtVfP9_iz-qhyP9NkB4QxfIoucR3z9Gu1fgZRB3b1U6tY6S99Wfs9nSMw",
    "link": "https://www.amazon.in/s?k=urea+fertilizer",
  },
  {
    "name": "Soil Enhancer Mix",
    "description": "Improves soil nutrients and water retention.",
    "category": "Fertilizer",
    "price": 280,
    "image": "https://encrypted-tbn1.gstatic.com/shopping?q=tbn:ANd9GcR4_kJb21Bh8iGSSVM1TKIiuuh4GwmhZFxm_-pYzf2ckKGUXd3pLLLHHySxWUDwEE_NFFKuiy7wMzu1Rid7O7r_noNljMTefOnFxpKndP820qJzRNBB8RfaVQ",
     "link": "https://www.amazon.in/s?k=soil+nutrient+mix",
  },
  {
    "name": "Potash Fertilizer",
    "description": "Enhances crop strength and immunity.",
    "category": "Fertilizer",
    "price": 390,
    "image": "https://encrypted-tbn0.gstatic.com/shopping?q=tbn:ANd9GcT7b1mafHssdkZiG1mOm0Jy6i8Aec-qcPmWIZe_-N5Z6zFcDm6EX8Yv5ak-H5QKzninit9B_wB7oc1YS2jRzljocO4lRZpb-gJKhyaQpo0X2mV482PtHTeN",
    "link": "https://www.amazon.in/s?k=potash+fertilizer",
  },
  {
    "name": "Bio Fertilizer Granules",
    "description": "Eco-friendly fertilizer for soil microbes.",
    "category": "Fertilizer",
    "price": 350,
    "image": "https://m.media-amazon.com/images/I/71hQaV7SaJL._SX342_.jpg",
        "link": "https://www.amazon.in/s?k=bio+fertilizer",
  },
  {
    "name": "Phosphate Fertilizer",
    "description": "Helps wheat roots become stronger.",
    "category": "Fertilizer",
    "price": 420,
     "image":  "https://m.media-amazon.com/images/I/71sdAVtUvGL._SX342_.jpg",
       "link": "https://www.amazon.in/s?k=phosphate+fertilizer",
  },


  // 🧪 10 CROP MEDICINES
  {
    "name": "Wheat Fungicide Liquid",
    "description": "Protects wheat crops from fungi and diseases.",
    "category": "Medicine",
    "price": 999,
    "image": "https://m.media-amazon.com/images/I/310ykenzBgL._SX342_SY445_QL70_FMwebp_.jpg" ,
       "link": "https://www.amazon.in/s?k=wheat+fungicide",
  },
  {
    "name": "Crop Pesticide Super",
    "description": "Controls pests affecting wheat crops.",
    "category": "Medicine",
    "price": 850,
    "image": "https://m.media-amazon.com/images/I/31DXwRu3zxL._SX342_SY445_QL70_FMwebp_.jpg",
     "link": "https://www.amazon.in/s?k=crop+pesticide",
  },
  {
    "name": "Insect Killer for Crops",
    "description": "Kills insects quickly and safely.",
    "category": "Medicine",
    "price": 700,
    "image": "https://m.media-amazon.com/images/I/41ZregLA2TL._SX342_SY445_QL70_FMwebp_.jpg" ,
       "link": "https://www.amazon.in/s?k=insecticide",
  },
  {
    "name": "Neem Oil Organic",
    "description": "Natural pesticide for all plants.",
    "category": "Medicine",
    "price": 250,
    "image": "https://m.media-amazon.com/images/I/312ay4d51aL._SY300_SX300_QL70_FMwebp_.jpg" ,
    "link": "https://www.amazon.in/s?k=neem+oil+pesticide",
  },
  {
    "name": "Herbal Fungicide",
    "description": "Eco-friendly fungus protector.",
    "category": "Medicine",
    "price": 540,
    "image": "https://m.media-amazon.com/images/I/51vmSttGRuL._SX342_SY445_QL70_FMwebp_.jpg" ,
     "link": "https://www.amazon.in/s?k=herbal+fungicide",
  },
  {
    "name": "Crop Virus Controller",
    "description": "Protects wheat crops from viral infections.",
    "category": "Medicine",
    "price": 1100,
    "image": "https://m.media-amazon.com/images/I/31jin8f0YNL._SY445_SX342_QL70_FMwebp_.jpg",
     "link": "https://www.amazon.in/s?k=crop+virus+controller",
  },
  {
    "name": "Larvicide for Crops",
    "description": "Kills larvae in wheat and other crops.",
    "category": "Medicine",
    "price": 620,
    "image": "https://m.media-amazon.com/images/I/51g9YVNmtYL._SX342_.jpg" ,
      "link": "https://www.amazon.in/s?k=larvicide",
  },
  
  {
    "name": "Root Rot Treatment",
    "description": "Prevents root rot in wheat and soil.",
    "category": "Medicine",
    "price": 800,
    "image": "https://m.media-amazon.com/images/I/713vorr8u+L._SX342_.jpg",
    "link": "https://www.amazon.in/s?k=root+rot+treatment",
  },
  {
    "name": "All-in-One Crop Solution",
    "description": "Boosts immunity and kills pests.",
    "category": "Medicine",
    "price": 1250,
    "image": "https://m.media-amazon.com/images/I/31iXKD9AzRL.jpg",
     "link": "https://www.amazon.in/s?k=crop+medicine",
  },
    // ... (keep all other products exactly as before)
    // For brevity I haven't repeated every product in this snippet — keep your original list here.
  ];

  List<Map<String, dynamic>> get filteredProducts {
    return allProducts.where((product) {
      final matchCategory =
          selectedCategory == "All" || product["category"] == selectedCategory;

      final matchSearch =
          product["name"].toString().toLowerCase().contains(searchText.toLowerCase());

      return matchCategory && matchSearch;
    }).toList();
  }

  Future<void> openBuyLink(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> searchAmazon() async {
    if (searchText.isEmpty) return;
    final uri = Uri.parse("https://www.amazon.in/s?k=${searchText.replaceAll(" ", "+")}");
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  int getCrossAxisCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 1200) return 6;
    if (width > 800) return 4;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    // Use localized app title if you want to display it here
    final theme = Theme.of(context);

    return Scaffold(
      
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: tr('market_search_hint'),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => searchText = value);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  onPressed: searchAmazon,
                  child: Text(tr('market_amazon_btn')),
                ),
              ],
            ),
          ),

          // Category Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(
                labelText: tr('market_category_label'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: [
                DropdownMenuItem(value: "All", child: Text(tr('cat_all'))),
                DropdownMenuItem(value: "Seeds", child: Text(tr('cat_seeds'))),
                DropdownMenuItem(value: "Fertilizer", child: Text(tr('cat_fertilizer'))),
                DropdownMenuItem(value: "Medicine", child: Text(tr('cat_medicine'))),
              ],
              onChanged: (value) {
                setState(() => selectedCategory = value ?? "All");
              },
            ),
          ),

          const SizedBox(height: 8),

          // Product Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: getCrossAxisCount(context),
                childAspectRatio:
                    MediaQuery.of(context).size.width < 500 ? 0.60 : 0.80,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final item = filteredProducts[index];

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      // Image
                      Container(
                        height: MediaQuery.of(context).size.width < 600 ? 110 : 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius:
                              const BorderRadius.vertical(top: Radius.circular(15)),
                          image: DecorationImage(
                            image: NetworkImage(item["image"]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      // Content area
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item["name"].toString(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                item["description"].toString(),
                                style: const TextStyle(fontSize: 11),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Text(
                                "₹${item["price"]}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () => openBuyLink(item["link"]),
                                  child: Text(tr('market_buy_now'),
                                      style:
                                          const TextStyle(fontSize: 13)),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
