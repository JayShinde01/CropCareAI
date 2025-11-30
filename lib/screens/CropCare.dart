import 'package:flutter/material.dart';

class Cropcare extends StatefulWidget {
  const Cropcare({super.key});

  @override
  State<Cropcare> createState() => _CropcareState();
}

class _CropcareState extends State<Cropcare> {
  // Enhanced wheat disease data structure to match the improved UI code
  List<Map<String, dynamic>> wheatDiseases = [
    {
      "name": "Wheat Rust (Stem, Leaf, Stripe)",
      // Use "image" for the thumbnail/main image
      "image": "https://cs-assets.bayer.com/is/image/bayer/leaf-rust-fungicide-crop-protection",
      // Use "images" for a gallery if multiple images are available
      "images": [
        "https://agritech.tnau.ac.in/crop_protection/images/wheat_diseases/wheat%20leaf%20rust%20nice_1.jpg",
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS-7U7YfomxIWhHuynuRzuMuWl9phM_Asll4ftH-Pfmjyj0chiFbSGwMy1-K9Spt5qSCSXAxCgdJmvLNonuCkbLI4MqBFtQvOBPNdWQXJM&s=10", // Placeholder for Leaf Rust Image
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTQRILE_7c68t0UBENe4gHAgbdly3P4wXuDfdD3AulCsljPDgmygMlwm5o8nAIWtiY8b-k&usqp=CAU"  // Placeholder for Stripe Rust Image
      ],
      "cause": "Fungal infection by Puccinia species (P. graminis, P. triticina, P. striiformis)",
      "symptoms": [
        "Orange/yellow **rust pustules** on leaves and stems.",
        "Pustules rupture, releasing powdery spores.",
        "Reduced grain size and shriveled grains.",
        "Stunted growth in severe cases."
      ],
      "prevention": [
        "Use **rust-resistant varieties** appropriate for your region.",
        "Apply specialized **fungicides** (e.g., Triazoles) timely.",
        "Avoid late sowing, which can increase vulnerability."
      ],
      "severity": "high",
      "onset": "Throughout season",
      "recommended_pesticide": "Propiconazole or Azoxystrobin",
      "dosage": "As per product instructions (e.g., 500ml/ha)",
      "how_people_handled": [
        "Many farmers in Punjab report good results with a single spray of Propiconazole at flag leaf stage.",
        "Some use resistant seeds but still monitor closely during rainy periods."
      ]
    },
    {
      "name": "Karnal Bunt (Partial Bunt)",
      "image": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSgbV5uAtM9AjJ9SbupvfmpdRwTyAhQ4Yo7hA&s",
       "images": [
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSgbV5uAtM9AjJ9SbupvfmpdRwTyAhQ4Yo7hA&s",
        "https://www.tribuneindia.com/sortd-service/imaginary/v22-01/jpg/large/high?url=dGhldHJpYnVuZS1zb3J0ZC1wcm8tcHJvZC1zb3J0ZC9tZWRpYTU3ZGM3MmUwLTJhMmYtMTFmMC04NDBiLTBkMWUyZGMyZWRkYi5qcGc=", // Placeholder for Leaf Rust Image
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTCn8Bie6a5vhyVaIHx-wpzSL3c3WTjCznFyMsxGf6XAFBCl_saVkREaD8Qweup3SYl_NM&usqp=CAU"  // Placeholder for Stripe Rust Image
      ],
      "cause": "Fungus: Tilletia indica (a seed and soil-borne disease)",
      "symptoms": [
        "**Black powdery fungal masses** replacing parts of the wheat kernels.",
        "Strong, unpleasant **fishy smell** (trimethylamine) from infected grains.",
        "Reduced grain quality, unfit for consumption."
      ],
      "prevention": [
        "Use **seed treatment** with fungicides like Tebuconazole.",
        "Practice **crop rotation** to reduce pathogen load in the soil.",
        "Avoid excessive irrigation, especially during flowering time."
      ],
      "severity": "moderate",
      "onset": "Flowering to maturity",
      "recommended_pesticide": "Tebuconazole (as seed treatment)",
      "how_people_handled": [
        "Seed treatment worked well, but irrigation control was difficult during unexpected rain."
      ]
    },
    {
      "name": "Powdery Mildew",
      "image": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTyb9wJxHN_PWcoNDcnI532gWfzfx3UckdyBg&s",
       "images": [
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTyb9wJxHN_PWcoNDcnI532gWfzfx3UckdyBg&s",
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQoEAdqkfEsPyNIz2sTmD15JHcLFlMwO5HUMg&s", // Placeholder for Leaf Rust Image
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTuyip00FD6WBkem6TfDLQ118QQ90bjeT10Yw&s"  // Placeholder for Stripe Rust Image
      ],
      "cause": "Fungus: Blumeria graminis (thrives in cool, humid conditions)",
      "symptoms": [
        "Distinctive **white powdery patches** on the upper surface of leaves and stems.",
        "Patches turn gray/brown over time.",
        "Reduced ability of the plant to photosynthesize."
      ],
      "prevention": [
        "Avoid **dense planting** to ensure good airflow.",
        "Apply **sulphur-based fungicides** early on.",
        "Select and use resistant cultivars if known to be a local issue."
      ],
      "severity": "low",
      "onset": "Early spring",
      "recommended_pesticide": "Sulfur wettable powder or Triadimefon",
      "dosage": "2 kg/ha (Sulphur)",
      "how_people_handled": []
    },
    {
  "name": "Loose Smut",
  "image":
      "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQy9Gfg3q2jsjb1sSWsWIW7GRdnnr9L0p9xiQ&s",
  "images": [
    "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTAyurMnkFeSpFd5-wVAUZ_kYbPWcQ1ImkpSg&s",
    "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQuDBMSatQIYvUxClXkCTxaiiveRG5q-K_StA&s",
    "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQoeO_Cg3mtZ8ADm0DXDy23qstTxd5fMLl2Iw&s"
  ],
  "cause": "Fungus: Ustilago tritici (carried inside seed embryo)",
  "symptoms": [
    "Entire wheat ear replaced by black, sooty spores.",
    "Infected ears emerge earlier.",
    "Spores easily blow away leaving bare stalk."
  ],
  "prevention": [
    "Use disease-free certified seeds.",
    "Hot water seed treatment.",
    "Apply systemic seed fungicides like Carboxin."
  ],
  "severity": "moderate",
  "onset": "Heading stage",
  "recommended_pesticide": "Carboxin or Tebuconazole",
  "how_people_handled": [
    "Many farmers use certified seed to avoid infection.",
    "Hot-water seed treatment significantly reduced spread in many areas."
  ]
},

{
  "name": "Barley Yellow Dwarf Virus (BYDV)",
  "image":
      "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS8a1TSKYVt3b5ivcUB1Ix32ongjMbztJpKDQ&s",
  "images": [
    "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS8a1TSKYVt3b5ivcUB1Ix32ongjMbztJpKDQ&s",
    "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSmlIhnhQEZcL09cePf2PmCVPHVga4sIrvyOA&s",
    "https://upload.wikimedia.org/wikipedia/commons/thumb/9/9a/Barley_Yellow_Dwarf_Virus_in_wheat.jpg/250px-Barley_Yellow_Dwarf_Virus_in_wheat.jpg"
  ],
  "cause": "Virus spread by aphids",
  "symptoms": [
    "Yellowing and reddening of leaf tips.",
    "Severe stunting.",
    "Poor tillering and reduced yield."
  ],
  "prevention": [
    "Control aphids early using insecticides.",
    "Remove alternate host weeds.",
    "Use resistant varieties."
  ],
  "severity": "high",
  "onset": "Early growth stages",
  "recommended_pesticide": "Imidacloprid (controls aphids)",
  "treatment": [
    "No direct cure for BYDV virus.",
    "Control aphid carriers to prevent spread."
  ],
  "how_people_handled": [
    "Farmers observed improved yields after early aphid management.",
    "Removing wild grasses near fields reduced infection rate."
  ]
}

  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text("🌾 Wheat Disease Encyclopedia"),
      //   backgroundColor: Colors.green.shade700,
      //   foregroundColor: Colors.white,
      //   elevation: 4,
      // ),
      body: ListView.builder(
        itemCount: wheatDiseases.length,
        itemBuilder: (context, index) {
          final d = wheatDiseases[index];
          // Use a standard Card for the main container
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Theme(
              // use Theme to reduce default ExpansionTile padding and change icon color
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                collapsedIconColor: Colors.green.shade800,
                iconColor: Colors.green.shade800,
                // --- Leading Image/Icon ---
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.green.shade50,
                  // Use the primary image URL for the thumbnail
                  backgroundImage: (d["image"] != null)
                      ? NetworkImage(d["image"])
                      : null,
                  // Fallback icon if no image
                  child: (d["image"] == null)
                      ? const Icon(Icons.agriculture, size: 28, color: Colors.green)
                      : null,
                ),
                // --- Title ---
                title: Text(
                  d["name"] ?? 'Unknown Disease',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                // --- Subtitle (Severity & Onset) ---
                subtitle: Row(
                  children: [
                    // severity badge
                    _buildSeverityBadge(d["severity"]),
                    if (d["onset"] != null) ...[
                      const Icon(Icons.schedule, size: 14, color: Colors.black54),
                      const SizedBox(width: 4),
                      Text(
                        d["onset"],
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    ]
                  ],
                ),
                // --- Expanded Content ---
                childrenPadding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
                children: [
                  // Disease Image Gallery (Big Image First)
                  if (d["image"] != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 170,
                          width: double.infinity,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              d["image"],
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green.shade800));
                              },
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.shade100,
                                child: const Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // small thumbnails row if multiple images are available
                        if (d["images"] is List && (d["images"] as List).length > 1)
                          SizedBox(
                            height: 48,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: (d["images"] as List).length,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (context, tIdx) {
                                final url = (d["images"] as List)[tIdx];
                                return InkWell(
                                  onTap: () {
                                    // simple UI: show tapped image in a dialog for larger view
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => Dialog(
                                        child: Stack(
                                          children: [
                                            Image.network(url, fit: BoxFit.contain),
                                            Positioned(
                                              right: 6,
                                              top: 6,
                                              child: IconButton(
                                                icon: const Icon(Icons.close, color: Colors.white),
                                                onPressed: () => Navigator.of(ctx).pop(),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(url, width: 80, height: 48, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade100)),
                                  ),
                                );
                              },
                            ),
                          ),
                        if (d["images"] is List && (d["images"] as List).length > 1) const SizedBox(height: 12),
                      ],
                    ),

                  // Cause
                  InfoRow(
                    icon: Icons.science,
                    title: '🔬 What Causes It?',
                    content: d["cause"] ?? 'Information not available',
                  ),
                  const SizedBox(height: 10),

                  // Symptoms (bullet style for easy reading)
                  InfoRow(
                    icon: Icons.healing,
                    title: '🚨 Key Symptoms (What to Look For)',
                    contentWidget: SymptomsWidget(symptoms: d["symptoms"]),
                  ),
                  const SizedBox(height: 10),

                  // Prevention (numbered steps)
                  InfoRow(
                    icon: Icons.shield,
                    title: '✅ How to Prevent It',
                    contentWidget: PreventionWidget(prevention: d["prevention"]),
                  ),
                  const SizedBox(height: 10),

                  // Treatment steps (if provided show steps)
                  if (d["treatment"] != null)
                    InfoRow(
                      icon: Icons.local_hospital,
                      title: '🩹 Immediate Treatment Steps',
                      contentWidget: TreatmentWidget(treatment: d["treatment"]),
                    ),
                  if (d["treatment"] != null) const SizedBox(height: 10),

                  // Recommended pesticide & dosage
                  if (d["recommended_pesticide"] != null)
                    InfoRow(
                      icon: Icons.medical_services,
                      title: '🛒 Recommended Product',
                      content:
                          '${d["recommended_pesticide"]}${d["dosage"] != null ? " — Dosage: ${d["dosage"]}" : ""}',
                    ),
                  const SizedBox(height: 10),

                  // Farmer feedback — simple cards, easy language
                  const Text('🧑‍🌾 Farmer Community Feedback', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  if (d["how_people_handled"] is List && (d["how_people_handled"] as List).isNotEmpty)
                    Column(
                      children: (d["how_people_handled"] as List).map<Widget>((fb) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 34, 41, 26),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.person, size: 20, color: Colors.green.shade800),
                              const SizedBox(width: 8),
                              Expanded(child: Text(fb, style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic))),
                            ],
                          ),
                        );
                      }).toList(),
                    )
                  else
                    const Text(
                      'No community feedback yet. Share your experience to help others!',
                      style: TextStyle(color: Colors.black54),
                    ),
                  const SizedBox(height: 12),

                  // Action row: mark tried, add feedback, call expert
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                          label: const Text('I TRIED THIS', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as tried! Your feedback is valuable.')));
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        icon: Icon(Icons.message_outlined, color: Colors.green.shade700),
                        label: const Text('Feedback'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          foregroundColor: Colors.green.shade700,
                          side: BorderSide(color: Colors.green.shade700, width: 1.5),
                        ),
                        onPressed: () => _showFeedbackDialog(context, d["name"]),
                      ),
                      const SizedBox(width: 10),
                      // Call Expert Button (more prominent)
                      CircleAvatar(
                        backgroundColor: Colors.red.shade600,
                        child: IconButton(
                          icon: const Icon(Icons.call, color: Colors.white),
                          tooltip: 'Call Local Agronomist',
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📞 Connecting to expert... (Action placeholder)')));
                          },
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- HELPER FUNCTIONS ---

  Widget _buildSeverityBadge(String? severity) {
    severity = severity?.toLowerCase() ?? 'moderate';
    Color color;
    Color bgColor;
    String label;

    switch (severity) {
      case 'high':
        color = Colors.red.shade800;
        bgColor = Colors.red.shade100;
        label = 'HIGH RISK';
        break;
      case 'low':
        color = Colors.green.shade800;
        bgColor = Colors.green.shade100;
        label = 'LOW RISK';
        break;
      case 'moderate':
      default:
        color = Colors.orange.shade800;
        bgColor = Colors.orange.shade100;
        label = 'MODERATE RISK';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(right: 8, top: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context, String diseaseName) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Share Experience on $diseaseName'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'e.g., "Used fungicide, symptoms cleared in 5 days."'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                // In a real app: save feedback to backend / local DB
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanks for sharing! Your feedback will help other farmers.')));
              }
            },
            child: const Text('Submit'),
          )
        ],
      ),
    );
  }
}

// -----------------------------
// Helper widgets (Moved outside of State class for clarity)
// -----------------------------

// Simple row with icon, title and either plain text or a custom widget for content
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? content;
  final Widget? contentWidget;

  const InfoRow({
    super.key,
    required this.icon,
    required this.title,
    this.content,
    this.contentWidget,
  });

  @override
  Widget build(BuildContext context) {
    final Widget body = contentWidget ??
        Text(
          content ?? 'Not available',
          style: const TextStyle(fontSize: 14),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.green.shade800),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              body,
            ]),
          ),
        ],
      ),
    );
  }
}

// Symptoms widget: shows bullet points for easy reading
class SymptomsWidget extends StatelessWidget {
  final dynamic symptoms;
  const SymptomsWidget({super.key, required this.symptoms});

  @override
  Widget build(BuildContext context) {
    final List<String> bullets = [];
    if (symptoms == null) {
      bullets.add('No information available');
    } else if (symptoms is String) {
      // split by common separators for readability
      bullets.addAll(symptoms.split(RegExp(r'[,•\n]')).map((s) => s.trim()).where((s) => s.isNotEmpty));
    } else if (symptoms is List) {
      bullets.addAll((symptoms as List).map((e) => e.toString().trim()).where((s) => s.isNotEmpty));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: bullets.map((b) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('• ', style: TextStyle(fontSize: 16, color: Colors.black54)),
          Expanded(child: Text(b, style: const TextStyle(fontSize: 14))),
        ]),
      )).toList(),
    );
  }
}

// Prevention widget: shows numbered steps for clear action items
class PreventionWidget extends StatelessWidget {
  final dynamic prevention;
  const PreventionWidget({super.key, required this.prevention});

  @override
  Widget build(BuildContext context) {
    final List<String> steps = [];
    if (prevention == null) {
      steps.add('Not available');
    } else if (prevention is String) {
      // attempt to split by sentences / semicolons
      steps.addAll(prevention.split(RegExp(r'[.;\n]')).map((s) => s.trim()).where((s) => s.isNotEmpty));
    } else if (prevention is List) {
      steps.addAll((prevention as List).map((e) => e.toString().trim()).where((s) => s.isNotEmpty));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps.asMap().entries.map((e) {
        final idx = e.key + 1;
        final text = e.value;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(6)),
                alignment: Alignment.center,
                child: Text('$idx', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// Treatment widget: show step list clearly (similar to Prevention but distinct styling)
class TreatmentWidget extends StatelessWidget {
  final dynamic treatment;
  const TreatmentWidget({super.key, required this.treatment});

  @override
  Widget build(BuildContext context) {
    final List<String> steps = [];
    if (treatment == null) {
      steps.add('No treatment info');
    } else if (treatment is String) {
      steps.addAll(treatment.split(RegExp(r'[.;\n]')).map((s) => s.trim()).where((s) => s.isNotEmpty));
    } else if (treatment is List) {
      steps.addAll((treatment as List).map((e) => e.toString().trim()).where((s) => s.isNotEmpty));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps.asMap().entries.map((entry) {
        final idx = entry.key + 1;
        final txt = entry.value;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(radius: 12, backgroundColor: Colors.red.shade100, child: Text('$idx', style: TextStyle(fontSize: 12, color: Colors.red.shade800, fontWeight: FontWeight.w500))),
              const SizedBox(width: 10),
              Expanded(child: Text(txt, style: const TextStyle(fontSize: 14))),
            ],
          ),
        );
      }).toList(),
    );
  }
}