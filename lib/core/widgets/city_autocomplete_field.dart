import 'package:flutter/material.dart';
import '../constants/indonesia_cities.dart';

class CityAutocompleteField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;
  final bool wajib;

  const CityAutocompleteField({
    super.key,
    required this.controller,
    this.labelText = 'Tempat Lahir',
    this.prefixIcon = Icons.place_outlined,
    this.wajib = false,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) return const Iterable.empty();
        return indonesiaCities.where(
          (city) => city.toLowerCase().contains(query),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Text(option, style: const TextStyle(fontSize: 14)),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      fieldViewBuilder: (context, fieldController, focusNode, onSubmitted) {
        // Sinkronkan ke controller luar saat teks berubah
        fieldController.addListener(() {
          if (controller.text != fieldController.text) {
            controller.text = fieldController.text;
          }
        });
        return TextFormField(
          controller: fieldController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: labelText,
            prefixIcon: Icon(prefixIcon),
            hintText: 'Ketik nama kota/kabupaten...',
          ),
          validator: wajib
              ? (v) =>
                    (v == null || v.trim().isEmpty) ? 'Field wajib diisi' : null
              : null,
          onFieldSubmitted: (_) => onSubmitted(),
        );
      },
      onSelected: (selected) {
        controller.text = selected;
      },
    );
  }
}
