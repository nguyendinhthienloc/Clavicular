import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hackathon_clavicular/config/app_config.dart';
class ViewportDiagnosis extends StatefulWidget {
  const ViewportDiagnosis({
    super.key,
    required this.isDarkMode,
    required this.selectedPart,
  });

  final bool isDarkMode;
  final String selectedPart;

  @override
  State<ViewportDiagnosis> createState() => _ViewportDiagnosisState();
}

class _ViewportDiagnosisState extends State<ViewportDiagnosis> {
  final TextEditingController _notesController = TextEditingController();

  String? _selectedSeverity;
  String? _selectedPainType;
  String? _selectedDuration;
  String? _selectedActivity;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = widget.isDarkMode;

    final Color viewportBackground = isDarkMode
        ? const Color(0xFF1F1F1F)
        : const Color(0xFFF4F6F8);
    final Color viewportBorder = isDarkMode
        ? const Color(0xFF2C2C2C)
        : const Color(0xFFD4D9E0);
    final Color bodyTextColor = isDarkMode
        ? Colors.white
        : const Color(0xFF1F2937);
    final Color composerBackground = isDarkMode
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFFFFFFF);
    final Color composerBorder = isDarkMode
        ? const Color(0xFF454545)
        : const Color(0xFFD1D5DB);
    final Color inputTextColor = isDarkMode
        ? const Color(0xFFE3E3E3)
        : const Color(0xFF111827);
    final Color inputHintColor = isDarkMode
        ? const Color(0xFF9C9C9C)
        : const Color(0xFF6B7280);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: viewportBackground,
          border: Border.all(color: viewportBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Scaffold(
          backgroundColor: viewportBackground,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'clavicular',
                      style: GoogleFonts.montserrat(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: bodyTextColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: appConfig.isDarkMode
                            ? const Color(0xFF000000)
                            : const Color(0xFFD6D6DB),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'diagnosis',
                        style: GoogleFonts.montserrat(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: appConfig.isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: widget.selectedPart,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: composerBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: composerBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: composerBorder),
                          ),
                        ),
                        style: GoogleFonts.montserrat(color: inputTextColor),
                        dropdownColor: composerBackground,
                        items: [
                          DropdownMenuItem(
                            value: widget.selectedPart,
                            child: Text(widget.selectedPart),
                          ),
                        ],
                        onChanged: (_) {},
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedSeverity,
                        decoration: InputDecoration(
                          hintText: 'Select severity',
                          hintStyle: GoogleFonts.montserrat(
                            color: inputHintColor,
                          ),
                          filled: true,
                          fillColor: composerBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: composerBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: composerBorder),
                          ),
                        ),
                        style: GoogleFonts.montserrat(color: inputTextColor),
                        dropdownColor: composerBackground,
                        items: const [
                          DropdownMenuItem(value: 'Mild', child: Text('Mild')),
                          DropdownMenuItem(
                            value: 'Moderate',
                            child: Text('Moderate'),
                          ),
                          DropdownMenuItem(
                            value: 'Severe',
                            child: Text('Severe'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedSeverity = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedPainType,
                        decoration: InputDecoration(
                          hintText: 'Select pain type',
                          hintStyle: GoogleFonts.montserrat(
                            color: inputHintColor,
                          ),
                          filled: true,
                          fillColor: composerBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: composerBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: composerBorder),
                          ),
                        ),
                        style: GoogleFonts.montserrat(color: inputTextColor),
                        dropdownColor: composerBackground,
                        items: const [
                          DropdownMenuItem(
                            value: 'sharp',
                            child: Text('Sharp'),
                          ),
                          DropdownMenuItem(value: 'dull', child: Text('Dull')),
                          DropdownMenuItem(
                            value: 'throbbing',
                            child: Text('Throbbing'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedPainType = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedDuration,
                        decoration: InputDecoration(
                          hintText: 'Select duration',
                          hintStyle: GoogleFonts.montserrat(
                            color: inputHintColor,
                          ),
                          filled: true,
                          fillColor: composerBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: composerBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: composerBorder),
                          ),
                        ),
                        style: GoogleFonts.montserrat(color: inputTextColor),
                        dropdownColor: composerBackground,
                        items: const [
                          DropdownMenuItem(
                            value: '< 1 week',
                            child: Text('< 1 week'),
                          ),
                          DropdownMenuItem(
                            value: '1-4 weeks',
                            child: Text('1-4 weeks'),
                          ),
                          DropdownMenuItem(
                            value: '> 1 month',
                            child: Text('> 1 month'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedDuration = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedActivity,
                        decoration: InputDecoration(
                          hintText: 'Select activity trigger',
                          hintStyle: GoogleFonts.montserrat(
                            color: inputHintColor,
                          ),
                          filled: true,
                          fillColor: composerBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: composerBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: composerBorder),
                          ),
                        ),
                        style: GoogleFonts.montserrat(color: inputTextColor),
                        dropdownColor: composerBackground,
                        items: const [
                          DropdownMenuItem(value: 'Rest', child: Text('Rest')),
                          DropdownMenuItem(
                            value: 'Movement',
                            child: Text('Movement'),
                          ),
                          DropdownMenuItem(
                            value: 'Sports',
                            child: Text('Sports'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedActivity = value;
                          });
                        },
                      ),
                      const Spacer(),
                      Container(
                        width: double.infinity,
                        height: 118,
                        decoration: BoxDecoration(
                          color: composerBackground,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: composerBorder),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 12, 14, 10),
                          child: Column(
                            children: [
                              TextField(
                                controller: _notesController,
                                maxLines: 1,
                                style: GoogleFonts.montserrat(
                                  color: inputTextColor,
                                  fontSize: 16,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Add notes for diagnosis...',
                                  hintStyle: GoogleFonts.montserrat(
                                    color: inputHintColor,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                              const Spacer(),
                              const Align(
                                alignment: Alignment.centerRight,
                                child: Icon(Icons.graphic_eq),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Center(
                  child: SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'get diagnosis',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
