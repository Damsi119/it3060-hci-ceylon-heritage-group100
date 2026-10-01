import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class OtpCodeInput extends StatefulWidget {
  const OtpCodeInput({super.key, required this.controller, this.length = 6});

  final TextEditingController controller;
  final int length;

  @override
  State<OtpCodeInput> createState() => _OtpCodeInputState();
}

class _OtpCodeInputState extends State<OtpCodeInput> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _focusNode.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.text;
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Stack(
        children: [
          Opacity(
            opacity: 0,
            child: SizedBox(
              height: 1,
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                maxLength: widget.length,
                onChanged: (text) {
                  final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
                  if (digits != text) {
                    widget.controller.value = TextEditingValue(
                      text: digits.substring(
                        0,
                        digits.length.clamp(0, widget.length).toInt(),
                      ),
                      selection: TextSelection.collapsed(
                        offset: digits.length.clamp(0, widget.length).toInt(),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(widget.length, (index) {
              final active = value.length == index;
              final hasValue = index < value.length;
              return Container(
                width: 44,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: active ? AppColors.primary : AppColors.border,
                    width: active ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  hasValue ? value[index] : '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: AppColors.primaryDark,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
