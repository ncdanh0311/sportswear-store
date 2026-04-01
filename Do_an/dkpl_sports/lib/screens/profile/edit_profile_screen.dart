import 'package:flutter/material.dart';
import '../../core/user_session.dart';
import '../../core/constants/app_colors.dart';
import '../../services/profile_service.dart'; // Import Service

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String _selectedGender = 'Nam';
  DateTime? _selectedDob;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final session = UserSession();
    _nameController.text = session.fullName ?? '';
    _phoneController.text = session.phone ?? '';
    _addressController.text = session.address ?? '';
    if (session.gender != null && session.gender!.isNotEmpty)
      _selectedGender = session.gender!;
    _selectedDob = session.dob;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDob)
      setState(() => _selectedDob = picked);
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    Map<String, dynamic> dataToUpdate = {
      'full_name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'gender': _selectedGender,
      'dob': _selectedDob?.toIso8601String(),
    };

    // GỌI LOGIC TỪ PROFILE SERVICE
    final error = await ProfileService.instance.updateProfile(dataToUpdate);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Cập nhật hồ sơ thành công!"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: const Text(
          "Chỉnh sửa hồ sơ",
          style: TextStyle(color: Colors.white),
        ),
        leading: const BackButton(color: Colors.white),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildTextField("Họ và tên", _nameController, Icons.person),
                const SizedBox(height: 15),
                _buildTextField(
                  "Số điện thoại",
                  _phoneController,
                  Icons.phone,
                  isNumber: true,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  "Địa chỉ",
                  _addressController,
                  Icons.location_on,
                ),
                const SizedBox(height: 15),
                _buildGenderDropdown(),
                const SizedBox(height: 15),
                _buildDatePicker(),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Lưu thay đổi",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryBlue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: InputDecoration(
        labelText: "Giới tính",
        prefixIcon: const Icon(Icons.people, color: AppColors.primaryBlue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: ['Nam', 'Nữ', 'Khác']
          .map(
            (String value) =>
                DropdownMenuItem<String>(value: value, child: Text(value)),
          )
          .toList(),
      onChanged: (newValue) => setState(() => _selectedGender = newValue!),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: "Ngày sinh",
          prefixIcon: const Icon(
            Icons.calendar_today,
            color: AppColors.primaryBlue,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        child: Text(
          _selectedDob == null
              ? "Chưa cập nhật"
              : "${_selectedDob!.day}/${_selectedDob!.month}/${_selectedDob!.year}",
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
