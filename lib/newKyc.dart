import 'package:coincraze/AuthManager.dart';
import 'package:coincraze/BottomBar.dart';
import 'package:coincraze/Constants/API.dart';
import 'package:coincraze/Constants/Colors.dart';
import 'package:coincraze/HomeScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NewKYC extends StatefulWidget {
  const NewKYC({super.key});

  @override
  _NewKYCState createState() => _NewKYCState();
}

class _NewKYCState extends State<NewKYC> {
  int _currentStep = 0;
  final _formKeys = List.generate(3, (index) => GlobalKey<FormState>());
  final TextEditingController _FirstNameController = TextEditingController();
  final TextEditingController _LastNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedCountry = 'India';
  String _selectedDocumentType = 'Aadhaar';
  File? _frontImage;
  File? _backImage;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _ifscController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Ensure AuthManager is initialized
    AuthManager().init().then((_) {
      AuthManager().loadSavedDetails();
    });
  }

  @override
  void dispose() {
    _FirstNameController.dispose();
    _LastNameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isFront) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (isFront) {
          _frontImage = File(pickedFile.path);
        } else {
          _backImage = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _submitKYCData() async {
    final userId = AuthManager().userId;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in! Please log in again.')),
      );
      return;
    }

    try {
      final personalInfo = {
        'FirstName': _FirstNameController.text.trim(),
        'LastName': _LastNameController.text.trim(),
        'dob': _dobController.text.trim(),
        'phone': _phoneController.text.trim(),
      };
      final idProof = {
        'country': _selectedCountry,
        'documentType': _selectedDocumentType,
      };
      final bankDetails = {
        'bankName': _bankNameController.text.trim(),
        'accountNumber': _accountNumberController.text.trim(),
        'ifsc': _ifscController.text.trim(),
      };

      print('Submitting KYC with personalInfo: $personalInfo'); // Debug log
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$ProductionBaseUrl/submit-kyc'),
      );

      request.fields['userId'] = userId;
      request.fields['personalInfo'] = jsonEncode(personalInfo);
      request.fields['idProof'] = jsonEncode(idProof);
      request.fields['bankDetails'] = jsonEncode(bankDetails);
      print('Request Fields: ${request.fields}'); // Debug log

      if (_frontImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('frontImage', _frontImage!.path),
        );
      }
      if (_backImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('backImage', _backImage!.path),
        );
      }

      var response = await request.send();
      var responseData = await http.Response.fromStream(response);
      print('Response: ${responseData.body}'); // Debug log

      if (response.statusCode == 200) {
        // Update AuthManager with KYC data
        await AuthManager().saveLoginDetails({
          'user': {
            '_id': userId,
            'email': AuthManager().email,
            'phoneNumber': AuthManager().phoneNumber,
            'kyc': {
              'kycCompleted': true,
              'personalInfo': personalInfo,
              'idProof': idProof,
              'bankDetails': bankDetails,
            },
          },
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('KYC submitted successfully!')),
        );
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(builder: (context) => MainScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit KYC: ${responseData.body}')),
        );
      }
    } catch (e) {
      print('Error submitting KYC: $e'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting KYC: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'KYC Verification',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey.shade100,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStep(context, "Personal info", _currentStep >= 0, 1),
                Expanded(
                  child: _buildProgressLine(_currentStep >= 1 ? 0.5 : 0.0),
                ),
                _buildStep(context, "ID proof", _currentStep >= 1, 2),
                Expanded(
                  child: _buildProgressLine(_currentStep >= 2 ? 0.5 : 0.0),
                ),
                _buildStep(context, "Bank details", _currentStep >= 2, 3),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              _currentStep == 0
                  ? 'PERSONAL INFORMATION'
                  : _currentStep == 1
                      ? 'ID PROOF'
                      : 'BANK DETAILS',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            Expanded(child: _buildStepContent()),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKeys[_currentStep].currentState!.validate()) {
                    if (_currentStep == 1 &&
                        (_frontImage == null || _backImage == null)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please upload both front and back images'),
                        ),
                      );
                      return;
                    }
                    if (_currentStep < 2) {
                      setState(() {
                        _currentStep += 1;
                      });
                    } else {
                      _submitKYCData();
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.black ?? const Color.fromARGB(255, 11, 11, 11),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    CupertinoPageRoute(builder: (context) => MainScreen()),
                  );
                },
                child: Text(
                  "I'LL DO IT LATER",
                  style: TextStyle(
                    color: AppColors.black ?? Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(
      BuildContext context, String title, bool isActive, int stepNumber) {
    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: isActive
              ? (AppColors.black ?? Colors.green)
              : Colors.grey.shade300,
          child: isActive
              ? const Icon(Icons.check, color: Colors.white, size: 24)
              : Text(
                  stepNumber.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.black87 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(double progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: Colors.grey.shade300,
        color: AppColors.black ?? Colors.green,
        minHeight: 3,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return Form(
          key: _formKeys[0],
          child: Column(
            children: [
              _buildTextField(
                label: 'FIRST NAME',
                controller: _FirstNameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              _buildTextField(
                label: 'LAST NAME',
                controller: _LastNameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              _buildTextField(
                label: 'DATE OF BIRTH (DD/MM/YYYY)',
                controller: _dobController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your date of birth';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              _buildTextField(
                label: 'PHONE NUMBER',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty || value.length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
            ],
          ),
        );
      case 1:
        return Form(
          key: _formKeys[1],
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedCountry,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  labelText: 'COUNTRY',
                  labelStyle: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 16,
                  ),
                ),
                items: ['India', 'USA', 'UK']
                    .map(
                      (country) => DropdownMenuItem(
                        value: country,
                        child: Text(country),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCountry = value!;
                  });
                },
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _selectedDocumentType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  labelText: 'DOCUMENT TYPE',
                  labelStyle: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 16,
                  ),
                ),
                items: ['Aadhaar', 'Passport', 'Driving License']
                    .map(
                      (docType) => DropdownMenuItem(
                        value: docType,
                        child: Text(docType),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDocumentType = value!;
                  });
                },
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _pickImage(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.black ?? const Color.fromARGB(255, 11, 11, 11),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: const Text('Upload Front Image'),
                    ),
                  ),
                  if (_frontImage != null) ...[
                    const SizedBox(width: 10),
                    Image.file(_frontImage!, height: 100, width: 100),
                  ],
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _pickImage(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.black ?? const Color.fromARGB(255, 11, 11, 11),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: const Text('Upload Back Image'),
                    ),
                  ),
                  if (_backImage != null) ...[
                    const SizedBox(width: 10),
                    Image.file(_backImage!, height: 100, width: 100),
                  ],
                ],
              ),
            ],
          ),
        );
      case 2:
        return Form(
          key: _formKeys[2],
          child: Column(
            children: [
              _buildTextField(
                label: 'BANK NAME',
                controller: _bankNameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your bank name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              _buildTextField(
                label: 'ACCOUNT NUMBER',
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your account number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              _buildTextField(
                label: 'IFSC CODE',
                controller: _ifscController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your IFSC code';
                  }
                  return null;
                },
              ),
            ],
          ),
        );
      default:
        return Container();
    }
  }
}