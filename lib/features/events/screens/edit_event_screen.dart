import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/event_model.dart';
import '../../../shared/services/firestore_service.dart';

class EditEventScreen extends StatefulWidget {
  final Event event;
  const EditEventScreen({super.key, required this.event});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _carryController;
  late TextEditingController _providedController;
  late TextEditingController _imageUrlController;

  DateTime? _selectedDate;
  String? _selectedCategory;
  Uint8List? _imageBytes;
  String? _imageName;
  bool _isLoading = false;
  final FirestoreService _firestoreService = FirestoreService();

  final List<String> _categories = ['Clean Up', 'Plantation', 'Donation', 'Construction', 'General'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController = TextEditingController(text: widget.event.description);
    _locationController = TextEditingController(text: widget.event.location);
    _carryController = TextEditingController(text: widget.event.thingsToCarry.join(', '));
    _providedController = TextEditingController(text: widget.event.thingsProvided.join(', '));
    _imageUrlController = TextEditingController(text: widget.event.imageUrl);
    _selectedDate = widget.event.eventDate;
    _selectedCategory = widget.event.category;
  }

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
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      _imageName = pickedFile.name;
      _imageBytes = await pickedFile.readAsBytes();
      _imageUrlController.text = 'New image selected. Will be uploaded.';
      setState(() {});
    }
  }

  Future<void> _pickDateTime() async {
    final DateTime? date = await showDatePicker(
        context: context,
        initialDate: _selectedDate ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2101));
    if (date == null) return;
    final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate ?? DateTime.now()));
    if (time == null) return;
    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _updateForm() async {
    if (_formKey.currentState!.validate() && _selectedDate != null && _selectedCategory != null) {
      setState(() { _isLoading = true; });

      String finalImageUrl;
      if (_imageBytes != null && _imageName != null) {
        final newImageUrl = await _firestoreService.uploadImage(imageBytes: _imageBytes!, fileName: _imageName!);
        finalImageUrl = newImageUrl ?? widget.event.imageUrl;
      } else {
        finalImageUrl = _imageUrlController.text.trim();
      }

      Map<String, dynamic> updatedData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'location': _locationController.text,
        'eventDate': _selectedDate,
        'category': _selectedCategory,
        'imageUrl': finalImageUrl,
        'thingsToCarry': _carryController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'thingsProvided': _providedController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      };

      await _firestoreService.updateEvent(widget.event.id, updatedData);

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Event'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : IconButton(
                    icon: const Icon(Icons.check_circle_outline, size: 28),
                    onPressed: _updateForm,
                    tooltip: 'Update Event',
                  ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Event Image', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _imageBytes != null
                        ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                        : (widget.event.imageUrl.isNotEmpty
                            ? Image.network(widget.event.imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Center(child: Text('Could not load image')))
                            : const Center(child: Text('Tap to add an image'))),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(child: Text('OR', style: TextStyle(color: Colors.grey))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'Paste Image URL'),
                keyboardType: TextInputType.url,
                onChanged: (value) {
                  if (_imageBytes != null) {
                    setState(() {
                      _imageBytes = null;
                      _imageName = null;
                    });
                  }
                },
              ),
              const Divider(height: 40),
              const Text('Event Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Event Title'),
                validator: (value) => value!.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Category'),
                initialValue: _selectedCategory,
                onChanged: (String? newValue) => setState(() => _selectedCategory = newValue),
                items: _categories.map<DropdownMenuItem<String>>((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                validator: (value) => value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Date & Time',
                  hintText: _selectedDate == null ? 'Select Date & Time' : DateFormat.yMd().add_jm().format(_selectedDate!),
                ),
                onTap: _pickDateTime,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (value) => value!.isEmpty ? 'Please enter a location' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 4,
                validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
              ),
              const Divider(height: 40),
              ExpansionTile(
                title: const Text('Equipment Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                tilePadding: EdgeInsets.zero,
                initiallyExpanded: true,
                children: [
                  TextFormField(
                    controller: _carryController,
                    decoration: const InputDecoration(labelText: 'Things to Carry (comma-separated)'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _providedController,
                    decoration: const InputDecoration(labelText: 'Things Provided (comma-separated)'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}