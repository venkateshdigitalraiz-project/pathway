import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/custom_button.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class UserDetailsPage extends StatefulWidget {
  const UserDetailsPage({super.key});

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();

  // Gender options: 'Male', 'Female', 'Others'
  String _selectedGender = 'Male';

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    final user = authState.user;
    if (user != null) {
      if (user.fullName.isNotEmpty && user.fullName.toLowerCase() != 'user') {
        _fullNameController.text = user.fullName;
      }
      if (user.email.isNotEmpty) {
        _emailController.text = user.email;
      }
      if (user.gender != null && user.gender!.isNotEmpty) {
        _selectedGender = user.gender!;
      }
      if (user.reference != null && user.reference!.isNotEmpty) {
        _referenceController.text = user.reference!;
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    context.read<AuthBloc>().add(
      SaveUserDetailsEvent(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        reference: _referenceController.text.trim().isNotEmpty
            ? _referenceController.text.trim()
            : null,
        gender: _selectedGender,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'User Details',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.dashboardTextDark,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }

          if (state.status == AuthStatus.authenticated && !state.isFirstTime) {
            context.go(AppRoutes.main);
          }
        },
        builder: (context, state) {
          final isLoading = state.status == AuthStatus.loading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.badge_rounded,
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Complete Profile',
                                  style: AppTypography.titleMedium.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.dashboardTextDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Please provide your details to finish setting up your account.',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.dashboardTextMuted,
                                    fontSize: 13,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Full Name Field
                    _buildFieldLabel('Full Name', isRequired: true),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _fullNameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: _buildInputDecoration(
                        hintText: 'Enter your full name',
                        prefixIcon: Icons.person_outline_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Full name is required';
                        }
                        if (value.trim().length < 2) {
                          return 'Please enter a valid full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Email Field
                    _buildFieldLabel('Email Address', isRequired: true),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: _buildInputDecoration(
                        hintText: 'e.g. name@example.com',
                        prefixIcon: Icons.email_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email address is required';
                        }
                        final emailRegex = RegExp(
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                        );
                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Reference Field
                    _buildFieldLabel('Reference', isRequired: false),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _referenceController,
                      textInputAction: TextInputAction.done,
                      decoration: _buildInputDecoration(
                        hintText: 'Referral code or reference name (optional)',
                        prefixIcon: Icons.card_giftcard_rounded,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Gender Selection
                    _buildFieldLabel('Gender', isRequired: true),
                    const SizedBox(height: 10),
                    _buildGenderRadioGroup(),
                    const SizedBox(height: 36),

                    // Submit Button
                    CustomButton(
                      text: 'Complete Profile',
                      onPressed: isLoading ? null : _onSubmit,
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.dashboardTextDark,
          ),
        ),
        if (isRequired)
          const Text(
            ' *',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: AppColors.dashboardTextSubtle,
        fontSize: 14,
      ),
      prefixIcon: Icon(prefixIcon, color: AppColors.primary, size: 22),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.8),
      ),
    );
  }

  Widget _buildGenderRadioGroup() {
    final genderOptions = [
      {'label': 'Male', 'icon': Icons.male_rounded},
      {'label': 'Female', 'icon': Icons.female_rounded},
      {'label': 'Others', 'icon': Icons.transgender_rounded},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: genderOptions.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final label = option['label'] as String;
          final icon = option['icon'] as IconData;
          final isSelected = _selectedGender == label;

          return Column(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _selectedGender = label;
                  });
                },
                borderRadius: BorderRadius.vertical(
                  top: index == 0 ? const Radius.circular(16) : Radius.zero,
                  bottom: index == genderOptions.length - 1
                      ? const Radius.circular(16)
                      : Radius.zero,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.12)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          icon,
                          size: 20,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.dashboardTextMuted,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? AppColors.dashboardTextDark
                                : AppColors.dashboardTextMuted,
                          ),
                        ),
                      ),
                      Radio<String>(
                        value: label,
                        groupValue: _selectedGender,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedGender = val;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              if (index < genderOptions.length - 1)
                const Divider(height: 1, indent: 64, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
}
