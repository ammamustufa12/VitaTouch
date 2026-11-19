import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/person_profile.dart';
import '../../providers/profile_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_card.dart';
import '../../widgets/responsive_body.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _genders = ['Female', 'Male', 'Non-binary', 'Prefer not to say'];
  static const _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  final _name = TextEditingController();
  final _history = TextEditingController();
  final _allergies = TextEditingController();
  DateTime? _dob;
  String _gender = '';
  String _blood = '';
  bool _editing = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _loadFrom(context.read<ProfileProvider>().profile);
  }

  void _loadFrom(PersonProfile profile) {
    _name.text = profile.name;
    _history.text = profile.medicalHistory;
    _allergies.text = profile.allergies;
    _dob = profile.dateOfBirth;
    _gender = _genders.contains(profile.gender) ? profile.gender : '';
    _blood = _bloodGroups.contains(profile.bloodGroup) ? profile.bloodGroup : '';
  }

  @override
  void dispose() {
    _name.dispose();
    _history.dispose();
    _allergies.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      helpText: 'Date of birth',
      initialDate: _dob ?? DateTime(now.year - 30, now.month, now.day),
      firstDate: DateTime(now.year - 120, now.month, now.day),
      lastDate: now,
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _dob = picked;
      _formError = null;
    });
  }

  Future<void> _save() async {
    if (_dob != null && !isPlausibleBirthDate(_dob!, DateTime.now())) {
      setState(() {
        _formError = 'Enter a valid date of birth, or leave it empty.';
      });
      return;
    }
    final next = PersonProfile(
      name: _name.text.trim(),
      dateOfBirth: _dob,
      gender: _gender,
      bloodGroup: _blood,
      medicalHistory: _history.text.trim(),
      allergies: _allergies.text.trim(),
    );
    final saved = await context.read<ProfileProvider>().save(next);
    if (!mounted) {
      return;
    }
    if (!saved) {
      setState(() {
        _formError = context.read<ProfileProvider>().error;
      });
      return;
    }
    setState(() {
      _editing = false;
      _formError = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved on this device.')),
    );
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear profile?'),
          content: const Text(
            'Name, date of birth, and medical notes will be marked as not provided.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final cleared = await context.read<ProfileProvider>().clear();
    if (!mounted) {
      return;
    }
    if (!cleared) {
      setState(() => _formError = context.read<ProfileProvider>().error);
      return;
    }
    setState(() {
      _loadFrom(PersonProfile.empty);
      _editing = false;
      _formError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final profile = provider.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ResponsiveBody(
        child: provider.loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                children: [
                  Text(
                    'Only details you enter are stored on this device. Empty fields stay marked as not provided.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (provider.error != null && !_editing) ...[
                    const SizedBox(height: 12),
                    Text(
                      provider.error!,
                      style: const TextStyle(color: AppColors.heart),
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (!_editing)
                    _Summary(profile: profile)
                  else
                    _Editor(
                      name: _name,
                      history: _history,
                      allergies: _allergies,
                      dob: _dob,
                      gender: _gender,
                      blood: _blood,
                      genders: _genders,
                      bloodGroups: _bloodGroups,
                      formError: _formError,
                      saving: provider.saving,
                      onGender: (value) => setState(() => _gender = value ?? ''),
                      onBlood: (value) => setState(() => _blood = value ?? ''),
                      onPickDob: _pickDob,
                      onClearDob: () => setState(() => _dob = null),
                      onSave: _save,
                    ),
                  const SizedBox(height: 12),
                  if (!_editing)
                    FilledButton(
                      onPressed: () {
                        _loadFrom(profile);
                        setState(() => _editing = true);
                      },
                      child: const Text('Edit details'),
                    ),
                  if (_editing)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: OutlinedButton(
                        onPressed: provider.saving
                            ? null
                            : () => setState(() => _editing = false),
                        child: const Text('Cancel'),
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: provider.saving ? null : _clear,
                    child: const Text('Clear profile'),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.profile});

  final PersonProfile profile;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          _Row(label: 'Person name', value: providedText(profile.name)),
          _Row(label: 'Age', value: formatAge(profile.ageYears)),
          _Row(label: 'Date of birth', value: formatDate(profile.dateOfBirth)),
          _Row(label: 'Gender', value: providedText(profile.gender)),
          _Row(label: 'Blood group', value: providedText(profile.bloodGroup)),
          _Row(
            label: 'Medical history',
            value: providedText(profile.medicalHistory),
          ),
          _Row(label: 'Allergies', value: providedText(profile.allergies)),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final missing = value == AppConstants.notProvided;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 124,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: missing ? AppColors.muted : AppColors.text,
                fontStyle: missing ? FontStyle.italic : FontStyle.normal,
                fontWeight: missing ? FontWeight.w500 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Editor extends StatelessWidget {
  const _Editor({
    required this.name,
    required this.history,
    required this.allergies,
    required this.dob,
    required this.gender,
    required this.blood,
    required this.genders,
    required this.bloodGroups,
    required this.formError,
    required this.saving,
    required this.onGender,
    required this.onBlood,
    required this.onPickDob,
    required this.onClearDob,
    required this.onSave,
  });

  final TextEditingController name;
  final TextEditingController history;
  final TextEditingController allergies;
  final DateTime? dob;
  final String gender;
  final String blood;
  final List<String> genders;
  final List<String> bloodGroups;
  final String? formError;
  final bool saving;
  final ValueChanged<String?> onGender;
  final ValueChanged<String?> onBlood;
  final VoidCallback onPickDob;
  final VoidCallback onClearDob;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: name,
            textCapitalization: TextCapitalization.words,
            maxLength: 80,
            decoration: const InputDecoration(
              labelText: 'Person name',
              hintText: AppConstants.notProvided,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Age', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            formatAge(
              PersonProfile(dateOfBirth: dob).ageYears,
            ),
            style: const TextStyle(color: AppColors.muted),
          ),
          const Text(
            'Calculated from date of birth.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onPickDob,
            child: Text(
              dob == null ? 'Date of birth: Not provided' : 'Date of birth: ${formatDate(dob)}',
            ),
          ),
          if (dob != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onClearDob,
                child: const Text('Clear date of birth'),
              ),
            ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: gender.isEmpty ? null : gender,
            decoration: const InputDecoration(labelText: 'Gender'),
            hint: const Text(AppConstants.notProvided),
            items: [
              for (final option in genders)
                DropdownMenuItem(value: option, child: Text(option)),
            ],
            onChanged: saving ? null : onGender,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: blood.isEmpty ? null : blood,
            decoration: const InputDecoration(labelText: 'Blood group'),
            hint: const Text(AppConstants.notProvided),
            items: [
              for (final option in bloodGroups)
                DropdownMenuItem(value: option, child: Text(option)),
            ],
            onChanged: saving ? null : onBlood,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: history,
            maxLength: 2000,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Medical history',
              hintText: AppConstants.notProvided,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: allergies,
            maxLength: 1000,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Allergies',
              hintText: AppConstants.notProvided,
            ),
          ),
          if (formError != null) ...[
            const SizedBox(height: 8),
            Text(formError!, style: const TextStyle(color: AppColors.heart)),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: saving ? null : onSave,
            child: saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save profile'),
          ),
        ],
      ),
    );
  }
}
