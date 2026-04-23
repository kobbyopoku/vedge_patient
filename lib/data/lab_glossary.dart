/// Static plain-language explanations for the most common lab tests we
/// surface in result detail. Per spec §6.10 + §3 Q3, v1 ships static lookup
/// (no LLM calls). When a code isn't in the glossary, the "What this means"
/// card hides — no "unknown" placeholder.
///
/// Keys are LOINC codes when known, otherwise short canonical test codes
/// matching the backend's `lab_result.testCode`. Match logic is also
/// case-insensitive on the human test name as a fallback.
class LabGlossary {
  const LabGlossary._();

  /// keyed by uppercase test code OR uppercase test name.
  static const Map<String, LabExplanation> _byCode = {
    // ── Diabetes / glucose ─────────────────────────────────────
    'GLU': LabExplanation(
      title: 'Fasting glucose',
      blurb:
          'This is the level of sugar in your blood after not eating for at '
          'least 8 hours. It tells your clinician how your body handles sugar '
          'over time.',
    ),
    'GLUF': LabExplanation(
      title: 'Fasting glucose',
      blurb:
          'This is the level of sugar in your blood after not eating for at '
          'least 8 hours. It tells your clinician how your body handles sugar '
          'over time.',
    ),
    '14771-0': LabExplanation(
      title: 'Fasting glucose',
      blurb:
          'This is the level of sugar in your blood after not eating for at '
          'least 8 hours.',
    ),
    'HBA1C': LabExplanation(
      title: 'Hemoglobin A1c (HbA1c)',
      blurb:
          'A long-view of your blood sugar — the average over the past two to '
          'three months. Higher numbers mean more sugar has been in your '
          'blood for longer.',
    ),
    '4548-4': LabExplanation(
      title: 'Hemoglobin A1c (HbA1c)',
      blurb:
          'A long-view of your blood sugar — the average over the past two to '
          'three months.',
    ),

    // ── Lipids ─────────────────────────────────────────────────
    'CHOL': LabExplanation(
      title: 'Total cholesterol',
      blurb:
          'The total amount of cholesterol — a fat — in your blood. Some is '
          'needed; too much over time can build up in your arteries.',
    ),
    'LDL': LabExplanation(
      title: 'LDL cholesterol',
      blurb:
          '"Bad" cholesterol. High levels can build up in your arteries and '
          'raise the risk of heart problems.',
    ),
    'HDL': LabExplanation(
      title: 'HDL cholesterol',
      blurb:
          '"Good" cholesterol. Higher is generally better — it helps clear '
          'other cholesterol from your blood.',
    ),
    'TRIG': LabExplanation(
      title: 'Triglycerides',
      blurb:
          'A type of fat in your blood. High levels can also raise the risk '
          'of heart problems.',
    ),

    // ── Renal ──────────────────────────────────────────────────
    'CREA': LabExplanation(
      title: 'Creatinine',
      blurb:
          'A waste product your kidneys filter out. Too much in your blood '
          'can be a sign your kidneys aren\'t filtering as well as they '
          'could.',
    ),
    'BUN': LabExplanation(
      title: 'Blood urea nitrogen',
      blurb:
          'Another waste product. With creatinine, it gives a picture of how '
          'well your kidneys are working.',
    ),
    'EGFR': LabExplanation(
      title: 'Estimated glomerular filtration rate',
      blurb:
          'A calculation that estimates how much blood your kidneys filter '
          'every minute. Higher is better.',
    ),

    // ── Liver ──────────────────────────────────────────────────
    'ALT': LabExplanation(
      title: 'Alanine aminotransferase (ALT)',
      blurb:
          'A liver enzyme. High levels can mean your liver is irritated or '
          'damaged.',
    ),
    'AST': LabExplanation(
      title: 'Aspartate aminotransferase (AST)',
      blurb:
          'Another liver enzyme — also found in some other tissues. Often '
          'looked at alongside ALT.',
    ),
    'ALP': LabExplanation(
      title: 'Alkaline phosphatase (ALP)',
      blurb:
          'An enzyme found in your liver and bones. Levels can rise when '
          'either is under stress.',
    ),
    'BILT': LabExplanation(
      title: 'Total bilirubin',
      blurb:
          'A yellow substance made when red blood cells break down. High '
          'levels can show up as yellowing of the eyes or skin.',
    ),

    // ── CBC ────────────────────────────────────────────────────
    'HGB': LabExplanation(
      title: 'Hemoglobin',
      blurb:
          'The protein in red blood cells that carries oxygen. Low levels '
          'often cause tiredness — that\'s anemia.',
    ),
    'HCT': LabExplanation(
      title: 'Hematocrit',
      blurb:
          'The fraction of your blood made of red blood cells. Looked at '
          'alongside hemoglobin.',
    ),
    'WBC': LabExplanation(
      title: 'White blood cell count',
      blurb:
          'These cells fight infection. High or low numbers can mean your '
          'body is fighting something off.',
    ),
    'PLT': LabExplanation(
      title: 'Platelet count',
      blurb:
          'Platelets help your blood clot. Very low numbers raise the risk '
          'of bleeding; very high numbers can raise the risk of clots.',
    ),
    'RBC': LabExplanation(
      title: 'Red blood cell count',
      blurb:
          'The number of red blood cells. They carry oxygen around your body.',
    ),
    'MCV': LabExplanation(
      title: 'Mean corpuscular volume',
      blurb:
          'The average size of your red blood cells. Helps clinicians '
          'understand the cause of anemia.',
    ),

    // ── Electrolytes ───────────────────────────────────────────
    'NA': LabExplanation(
      title: 'Sodium',
      blurb:
          'A salt your body uses to balance fluids. Too high or too low can '
          'make you feel unwell.',
    ),
    'K': LabExplanation(
      title: 'Potassium',
      blurb:
          'Another important salt — used by your nerves and muscles, '
          'including your heart.',
    ),
    'CL': LabExplanation(
      title: 'Chloride',
      blurb:
          'A salt that works with sodium to keep your body\'s fluid balance.',
    ),
    'HCO3': LabExplanation(
      title: 'Bicarbonate',
      blurb:
          'Helps your body manage acidity. A clue to how your kidneys and '
          'lungs are working.',
    ),
    'CA': LabExplanation(
      title: 'Calcium',
      blurb:
          'Important for bones, nerves and muscles.',
    ),
    'MG': LabExplanation(
      title: 'Magnesium',
      blurb:
          'A mineral your body needs for many things — including muscle and '
          'nerve function.',
    ),

    // ── Thyroid ────────────────────────────────────────────────
    'TSH': LabExplanation(
      title: 'Thyroid stimulating hormone',
      blurb:
          'A signal from your brain that tells your thyroid how much hormone '
          'to make. The first test for many thyroid problems.',
    ),
    'T4': LabExplanation(
      title: 'Free T4 (thyroxine)',
      blurb:
          'A thyroid hormone. Looked at with TSH to understand thyroid '
          'function.',
    ),
    'T3': LabExplanation(
      title: 'Free T3 (triiodothyronine)',
      blurb:
          'Another thyroid hormone. Sometimes checked when TSH or T4 is off.',
    ),

    // ── Inflammation / general ─────────────────────────────────
    'CRP': LabExplanation(
      title: 'C-reactive protein',
      blurb:
          'Rises when there\'s inflammation in your body. Not specific to one '
          'cause — your clinician will read it with other clues.',
    ),
    'ESR': LabExplanation(
      title: 'Erythrocyte sedimentation rate (ESR)',
      blurb:
          'Another general marker of inflammation. Slow-changing — looked at '
          'over time.',
    ),
    'FERR': LabExplanation(
      title: 'Ferritin',
      blurb:
          'How much iron is stored in your body. Low ferritin means low iron '
          'reserves; high can be inflammation or other things.',
    ),

    // ── Common infections ──────────────────────────────────────
    'HIV': LabExplanation(
      title: 'HIV test',
      blurb:
          'Looks for HIV in your blood. A positive result needs follow-up '
          'tests to confirm.',
    ),
    'HBSAG': LabExplanation(
      title: 'Hepatitis B surface antigen',
      blurb:
          'Looks for active hepatitis B infection.',
    ),
    'HCV': LabExplanation(
      title: 'Hepatitis C antibody',
      blurb:
          'Looks for past or present hepatitis C infection.',
    ),
    'MAL': LabExplanation(
      title: 'Malaria parasite',
      blurb:
          'Looks for the parasite that causes malaria, usually using a blood '
          'smear or rapid test.',
    ),
    'PCT': LabExplanation(
      title: 'Procalcitonin',
      blurb:
          'A marker that often rises in bacterial infections. Helps decide if '
          'antibiotics are needed.',
    ),

    // ── Pregnancy & women's health ─────────────────────────────
    'BHCG': LabExplanation(
      title: 'Beta-hCG',
      blurb:
          'A pregnancy hormone. Used to confirm pregnancy and (in early '
          'pregnancy) track how it\'s progressing.',
    ),

    // ── Vitamin D ──────────────────────────────────────────────
    'VITD': LabExplanation(
      title: 'Vitamin D (25-OH)',
      blurb:
          'Tells you if you have enough vitamin D — important for bones and '
          'immune function.',
    ),
  };

  /// Look up an explanation by test code, or by test name as a fallback.
  /// Returns null when nothing matches — caller should hide the explainer
  /// card per spec §6.10.
  static LabExplanation? lookup({String? code, String? name}) {
    if (code != null && code.trim().isNotEmpty) {
      final normalizedCode = code.trim().toUpperCase();
      if (_byCode.containsKey(normalizedCode)) {
        return _byCode[normalizedCode];
      }
    }
    if (name != null && name.trim().isNotEmpty) {
      final normalizedName = name.trim().toLowerCase();
      for (final entry in _byCode.values) {
        if (entry.title.toLowerCase() == normalizedName) return entry;
      }
      // Soft contains-match for slight name variants.
      for (final entry in _byCode.values) {
        if (entry.title.toLowerCase().contains(normalizedName) ||
            normalizedName.contains(entry.title.toLowerCase())) {
          return entry;
        }
      }
    }
    return null;
  }

  /// Total number of distinct explanations indexed (for tests / metrics).
  static int get size => {for (final v in _byCode.values) v.title}.length;
}

class LabExplanation {
  const LabExplanation({required this.title, required this.blurb});
  final String title;
  final String blurb;
}
