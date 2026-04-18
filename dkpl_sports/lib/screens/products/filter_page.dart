import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/model_utils.dart';

class FilterPage extends StatefulWidget {
  const FilterPage({super.key});
  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  List<String> brands = ["Keep & Fly", "CP", "DonexPro", "Justplay", "Kamito", "Bulbal"];
  List<String> selectedBrands = [];
  List<String> categories = ["Quần áo bóng đá", "Áo khoác", "Quần short", "Gym / Yoga"];
  List<String> selectedCategories = [];
  
  RangeValues priceRange = const RangeValues(100000, 1000000);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Bộ lọc sản phẩm", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Thương hiệu", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: brands.map((b) => FilterChip(
                label: Text(b),
                selected: selectedBrands.contains(b),
                selectedColor: AppColors.primaryBlue.withOpacity(0.2),
                checkmarkColor: AppColors.primaryBlue,
                onSelected: (v) => setState(() => v ? selectedBrands.add(b) : selectedBrands.remove(b)),
              )).toList(),
            ),
            const SizedBox(height: 25),

            const Text("Loại sản phẩm", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: categories.map((c) => FilterChip(
                label: Text(c),
                selected: selectedCategories.contains(c),
                selectedColor: AppColors.primaryBlue.withOpacity(0.2),
                checkmarkColor: AppColors.primaryBlue,
                onSelected: (v) => setState(() => v ? selectedCategories.add(c) : selectedCategories.remove(c)),
              )).toList(),
            ),
            const SizedBox(height: 25),

            const Text("Khoảng giá (VNĐ)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              "${ModelUtils.formatVnd(priceRange.start)}  -  ${ModelUtils.formatVnd(priceRange.end)}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
            ),
            RangeSlider(
              values: priceRange,
              min: 0, max: 3000000, divisions: 100,
              activeColor: AppColors.primaryBlue, inactiveColor: Colors.grey.shade300,
              labels: RangeLabels(
                ModelUtils.formatVnd(priceRange.start),
                ModelUtils.formatVnd(priceRange.end),
              ),
              onChanged: (value) => setState(() => priceRange = value),
            ),
            const SizedBox(height: 40),

            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => setState(() { selectedBrands.clear(); selectedCategories.clear(); priceRange = const RangeValues(100000, 1000000); }), child: const Text("Xóa lọc", style: TextStyle(color: AppColors.textDark)))),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text("Áp dụng", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
