import 'package:flutter/material.dart';

class CitySearchScreen extends StatefulWidget {
  const CitySearchScreen({super.key});

  @override
  State<CitySearchScreen> createState() => _CitySearchScreenState();
}

class _CitySearchScreenState extends State<CitySearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  void _submit() {
    final city = _controller.text.trim();
    if (city.isEmpty) {
      setState(() {
        _errorText = 'Please enter a city name';
      });
      return;
    }
    Navigator.of(context).pop(city);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search City'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'City Name',
                hintText: 'Enter city name',
                errorText: _errorText,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    setState(() {
                      _errorText = null;
                    });
                  },
                ),
              ),
              onSubmitted: (_) => _submit(),
              textInputAction: TextInputAction.search,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Search'),
            ),
          ],
        ),
      ),
    );
  }
}
