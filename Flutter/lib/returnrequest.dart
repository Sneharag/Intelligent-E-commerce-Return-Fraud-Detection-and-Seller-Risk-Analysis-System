// ⚡ Return Request: Reason dropdown + image upload → Django backend

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// =====================================================
// 📦 IMPORTS (Required Libraries for Image Upload)
// =====================================================
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'dart:typed_data';

class ReturnRequest extends StatefulWidget {
  final String orderItemId;
  const ReturnRequest({Key? key, required this.orderItemId}) : super(key: key);

  @override
  State<ReturnRequest> createState() => _ReturnRequestState();
}

class _ReturnRequestState extends State<ReturnRequest> {
  // ── Reason dropdown ──
  final List<String> _reasons = [
    "Damaged product",
    "Wrong item delivered",
    "Item not as described",
    "Quality not satisfactory",
    "Received late",
    "Other",
  ];
  String? _selectedReason;

  // ── Description controller ──
  final TextEditingController _descriptionController = TextEditingController();

  // =====================================================
  // 📸 FILE UPLOAD VARIABLES
  // =====================================================
  PlatformFile? _selectedFile;
  Uint8List? _webFileBytes;
  String? _result;
  bool _isLoading = false;

  // ── E-commerce palette (yellow · charcoal · deep blue) ──
  static const Color _yellow     = Color(0xFFFACC15);
  static const Color _yellowDeep = Color(0xFFEAB308);
  static const Color _yellowSoft = Color(0xFFFEF9C3);

  static const Color _charcoal   = Color(0xFF1F2937);
  static const Color _charcoalDk = Color(0xFF111827);
  static const Color _ink        = Color(0xFF111827);
  static const Color _warmWhite  = Color(0xFFFAFAF9);
  static const Color _line       = Color(0xFFE7E5E4);
  static const Color _muted      = Color(0xFF78716C);
  static const Color _mutedSoft  = Color(0xFFA8A29E);

  static const Color _blue       = Color(0xFF1E3A8A);
  static const Color _blueMid    = Color(0xFF2563EB);
  static const Color _blueSoft   = Color(0xFFDBEAFE);

  static const Color _warn       = Color(0xFFC23D2C);
  static const Color _green      = Color(0xFF059669);
  static const Color _greenSoft  = Color(0xFFD1FAE5);

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // =====================================================
  // 📸 PICK FILE FUNCTION
  // =====================================================
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
        _result = null;
      });

      if (kIsWeb) {
        _webFileBytes = result.files.first.bytes;
      }
    }
  }
  // =====================================================
  // 📸 END FILE PICK SECTION
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _warmWhite,
      appBar: AppBar(
        title: const Text(
          "Return Request",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
        backgroundColor: _charcoal,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: SizedBox(
            width: 500,
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ══════════ HERO CARD ══════════
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_charcoalDk, _charcoal, Color(0xFF374151)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _charcoal.withOpacity(0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_yellow, _yellowDeep],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: _yellow.withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.assignment_return_rounded,
                            size: 26,
                            color: _charcoal,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Return Item",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                "Tell us what went wrong and we'll process your return.",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.65),
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ══════════ SECTION 1: REASON ══════════
                  _sectionLabel(
                    icon: Icons.report_problem_outlined,
                    text: "REASON FOR RETURN",
                  ),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _selectedReason != null
                            ? _yellowDeep
                            : _line,
                        width: _selectedReason != null ? 1.8 : 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _charcoal.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedReason,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _charcoal,
                      ),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(left: 4, right: 4),
                          child: Icon(
                            Icons.checklist_rounded,
                            color: _charcoal,
                            size: 20,
                          ),
                        ),
                        hintText: 'Select a reason',
                        hintStyle: TextStyle(
                          color: _mutedSoft,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      items: _reasons
                          .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(r),
                      ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedReason = val;
                        });
                      },
                    ),
                  ),

                  // ══════════ SECTION 2: DESCRIPTION ══════════
                  if (_selectedReason != null) ...[
                    const SizedBox(height: 22),
                    _sectionLabel(
                      icon: Icons.description_outlined,
                      text: "DESCRIPTION (OPTIONAL)",
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _line, width: 1.4),
                        boxShadow: [
                          BoxShadow(
                            color: _charcoal.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _descriptionController,
                        maxLines: 5,
                        maxLength: 500,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _ink,
                          height: 1.5,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          hintText: 'Please describe the issue in detail',
                          hintStyle: TextStyle(
                            color: _mutedSoft.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                            fontSize: 13.5,
                          ),
                          counterStyle: const TextStyle(
                            color: _mutedSoft,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],

                  // ══════════ SECTION 3: IMAGE UPLOAD ══════════
                  const SizedBox(height: 22),
                  _sectionLabel(
                    icon: Icons.photo_camera_outlined,
                    text: "ATTACH PROOF (REQUIRED)",
                  ),
                  const SizedBox(height: 12),

                  // ── Upload zone ──
                  GestureDetector(
                    onTap: _pickFile,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 22,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedFile == null
                            ? _yellowSoft.withOpacity(0.5)
                            : _greenSoft.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedFile == null
                              ? _yellow.withOpacity(0.6)
                              : _green.withOpacity(0.5),
                          width: 1.6,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: _selectedFile == null
                          ? Column(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _yellow.withOpacity(0.5),
                                width: 1.2,
                              ),
                            ),
                            child: const Icon(
                              Icons.cloud_upload_outlined,
                              color: _charcoal,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Tap to upload an image",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "PNG, JPG · Up to 5MB",
                            style: TextStyle(
                              fontSize: 11.5,
                              color: _muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                          : Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Image selected",
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w900,
                                    color: _green,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _selectedFile!.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _selectedFile = null;
                                _webFileBytes = null;
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _line,
                                  width: 1.2,
                                ),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: _warn,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),

                  // ══════════ SEND BUTTON ══════════
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                        // Basic validation
                        if (_selectedReason == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please select a reason"),
                              backgroundColor: _warn,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        if (_selectedFile == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please select an image"),
                              backgroundColor: _warn,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        setState(() => _isLoading = true);

                        try {
                          SharedPreferences sh = await SharedPreferences.getInstance();

                          // =====================================================
                          // 🌐 SERVER REQUEST (POST to Django)
                          // =====================================================
                          var request = await http.MultipartRequest(
                            'POST',
                            Uri.parse(
                                '${sh.getString('ip')}/user_returnproduct'),
                          );

                          request.fields['orderitem_id'] = widget.orderItemId;
                          request.fields['reason'] = _selectedReason!;
                          request.fields['description'] = _descriptionController.text.trim();
                          request.fields['user_id'] = sh.getString('user').toString();

                          if (kIsWeb) {
                            request.files.add(
                                http.MultipartFile.fromBytes(
                                  'file',
                                  _webFileBytes!,
                                  filename: _selectedFile!.name,
                                ));
                          } else {
                            request.files.add(
                                await http.MultipartFile.fromPath(
                                  'file',
                                  _selectedFile!.path!,
                                ));
                          }

                          var streamedResponse = await request.send();
                          var response = await http.Response.fromStream(
                              streamedResponse);
                          // =====================================================
                          // 🌐 END SERVER UPLOAD SECTION
                          // =====================================================
                          var jsonData = json.decode(response.body);

                          if (!mounted) return;

                          if (jsonData["status"] == "success") {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Return request submitted"),
                                backgroundColor: _charcoal,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            Navigator.pop(context, true);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(jsonData["message"] ??
                                    "Failed to submit"),
                                backgroundColor: _warn,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "Network error. Please try again."),
                              backgroundColor: _warn,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } finally {
                          if (mounted)
                            setState(() => _isLoading = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _charcoal,
                        foregroundColor: _yellow,
                        elevation: 6,
                        shadowColor: _charcoal.withOpacity(0.35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: _yellow,
                        ),
                      )
                          : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.send_rounded,
                            size: 18,
                            color: _yellow,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Send Return Request",
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                              color: _yellow,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ══════════ HELP NOTE ══════════
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _blueSoft.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _blue.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: _blue,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Make sure the image clearly shows the issue. Returns are usually processed within 3–5 business days.",
                            style: TextStyle(
                              fontSize: 12,
                              color: _ink.withOpacity(0.85),
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Section label helper ──
  Widget _sectionLabel({required IconData icon, required String text}) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: _yellowSoft,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _yellow.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Icon(icon, size: 13, color: _charcoal),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: _charcoal,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _yellow.withOpacity(0.5),
                  _yellow.withOpacity(0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}