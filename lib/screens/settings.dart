import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsScreen extends StatefulWidget {
  final Function(String phone, String threshold) onClose;
  final Function(String phone, String threshold) onChange;

  final String initialPhone;
  final String initialThreshold;

  const SettingsScreen({
    super.key,
    required this.onClose,
    required this.onChange,
    required this.initialPhone,
    required this.initialThreshold,
  });

  @override
  State<StatefulWidget> createState() {
    return SettingsState();
  }
}

class SettingsState extends State<SettingsScreen> {
  String phone = "";
  String threshold = "";

  @override
  void initState() {
    phone = widget.initialPhone;
    threshold = widget.initialThreshold;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              initialValue: widget.initialPhone,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                FilteringTextInputFormatter.digitsOnly
              ],
              decoration: const InputDecoration(
                labelText: "enter a phone number",
                hintText: "enter a phone number",
                icon: Icon(Icons.phone_iphone),
              ),
              onChanged: (value) {
                setState(() {
                  phone = value;
                });
                widget.onChange(phone, threshold);
              },
            ),
            TextFormField(
              initialValue: widget.initialThreshold,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                FilteringTextInputFormatter.digitsOnly
              ],
              decoration: const InputDecoration(
                labelText: "sensitivity",
                hintText: "sensitivity",
                icon: Icon(Icons.sensors),
              ),
              onChanged: (value) {
                setState(() {
                  threshold = value;
                });
                widget.onChange(phone, threshold);
              },
            )
          ],
        ),
      ),
    );
  }
}
