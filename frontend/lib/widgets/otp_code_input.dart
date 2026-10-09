import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class OtpCodeInput extends StatefulWidget {
  const OtpCodeInput({
    super.key,
    required this.controller,
    this.length = 6,
    this.activeColor = AppColors.primary,
    this.borderColor = AppColors.border,
    this.fillColor = AppColors.surface,
    this.textColor = AppColors.primaryDark,
  });

  final TextEditingController controller;
  final int length;
  final Color activeColor;
  final Color borderColor;
  final Color fillColor;
  final Color textColor;

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
          LayoutBuilder(
            builder: (context, constraints) {
              final gap = (constraints.maxWidth / 70)
                  .clamp(4.0, 8.0)
                  .toDouble();
              final tileWidth =
                  ((constraints.maxWidth - (gap * (widget.length - 1))) /
                          widget.length)
                      .clamp(30.0, 44.0)
                      .toDouble();
              final tileHeight = (tileWidth + 6).clamp(40.0, 50.0).toDouble();
              final fontSize = tileWidth < 38 ? 15.0 : 17.0;

              return Row(
                children: List.generate(widget.length, (index) {
                  final active = value.length == index;
                  final hasValue = index < value.length;
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == widget.length - 1 ? 0 : gap,
                    ),
                    child: Container(
                      width: tileWidth,
                      height: tileHeight,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: widget.fillColor,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: active
                              ? widget.activeColor
                              : widget.borderColor,
                          width: active ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        hasValue ? value[index] : '',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: fontSize,
                          color: widget.textColor,
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}
