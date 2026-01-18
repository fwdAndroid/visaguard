import 'package:flutter/material.dart';

Widget appField(String label, TextEditingController c) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextField(
      controller: c,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

class PrimaryButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final bool loading;

  const PrimaryButton(this.title, this.onTap, {this.loading = false, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: loading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(title),
      ),
    );
  }
}
