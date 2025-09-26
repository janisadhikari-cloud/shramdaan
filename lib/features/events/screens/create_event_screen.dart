import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/services/firestore_service.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});
  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _carryController = TextEditingController();
  final _providedController = TextEditingController();
  final _imageUrlController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedCategory;
  Uint8List? _imageBytes;
  String? _imageName;
  bool _isLoading = false;

  final FirestoreService _firestoreService = FirestoreService();
  final List<String> _categories = [
    'Clean Up',
    'Plantation',
    'Donation',
    'Construction',
    'General',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _carryController.dispose();
    _providedController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      _imageName = pickedFile.name;
      _imageBytes = await pickedFile.readAsBytes();
      // Clear the URL field if an image is picked
      _imageUrlController.clear();
      setState(() {});
    }
  }

  Future<void> _pickDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (date == null) return;
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
    );
    if (time == null) return;
    setState(() {
      _selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submitForm() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (!_formKey.currentState!.validate() ||
        _selectedDate == null ||
        _selectedCategory == null ||
        currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields.')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    String imageUrl = _imageUrlController.text.trim();

    if (imageUrl.isEmpty && _imageBytes != null && _imageName != null) {
      imageUrl =
          await _firestoreService.uploadImage(
            imageBytes: _imageBytes!,
            fileName: _imageName!,
          ) ??
          '';
    }

    final List<String> thingsToCarry = _carryController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final List<String> thingsProvided = _providedController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    await _firestoreService.addEvent(
      title: _titleController.text,
      description: _descriptionController.text,
      location: _locationController.text,
      eventDate: _selectedDate!,
      category: _selectedCategory!,
      organizerId: currentUser.uid,
      organizerName: currentUser.displayName ?? 'Anonymous',
      imageUrl: imageUrl,
      thingsToCarry: thingsToCarry,
      thingsProvided: thingsProvided,
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Event'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: _submitForm,
                    tooltip: 'Create Event',
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Event Image',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                color: Colors.grey,
                                size: 40,
                              ),
                              Text('Tap to upload image'),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(child: Text('OR')),
              const SizedBox(height: 8),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'Paste Image URL'),
                keyboardType: TextInputType.url,
              ),

              const Divider(height: 40),

              const Text(
                'Event Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Event Title'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Category'),
                initialValue: _selectedCategory,
                onChanged: (String? newValue) =>
                    setState(() => _selectedCategory = newValue),
                items: _categories
                    .map<DropdownMenuItem<String>>(
                      (String value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ),
                    )
                    .toList(),
                validator: (value) =>
                    value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Date & Time',
                  hintText: _selectedDate == null
                      ? 'Select Date & Time'
                      : DateFormat.yMd().add_jm().format(_selectedDate!),
                ),
                onTap: _pickDateTime,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a location' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 4,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a description' : null,
              ),

              const Divider(height: 40),

              ExpansionTile(
                title: const Text(
                  'Equipment Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                tilePadding: EdgeInsets.zero,
                children: [
                  TextFormField(
                    controller: _carryController,
                    decoration: const InputDecoration(
                      labelText: 'Things to Carry (comma-separated)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _providedController,
                    decoration: const InputDecoration(
                      labelText: 'Things Provided (comma-separated)',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
