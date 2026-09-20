// import 'package:flutter/material.dart';
//
// class CreateAccountPage extends StatefulWidget {
//   const CreateAccountPage({super.key});
//
//   @override
//   State<CreateAccountPage> createState() => _CreateAccountPageState();
// }
//
// class _CreateAccountPageState extends State<CreateAccountPage> {
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//   final TextEditingController confirmPasswordController =
//   TextEditingController();
//
//   bool obscurePassword = true;
//   bool obscureConfirmPassword = true;
//
//   void createAccount() {
//     final name = nameController.text.trim();
//     final email = emailController.text.trim();
//     final password = passwordController.text.trim();
//     final confirmPassword = confirmPasswordController.text.trim();
//
//     // Check empty fields
//     if (name.isEmpty ||
//         email.isEmpty ||
//         password.isEmpty ||
//         confirmPassword.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Please fill all fields',
//           ),
//         ),
//       );
//
//       return;
//     }
//
//     // Check password
//     if (password != confirmPassword) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Passwords do not match',
//           ),
//         ),
//       );
//
//       return;
//     }
//
//     // User data
//     final userData = {
//       'name': name,
//       'email': email,
//       'password': password,
//     };
//
//     print('User Data: $userData');
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text(
//           'Account created successfully',
//         ),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     nameController.dispose();
//     emailController.dispose();
//     passwordController.dispose();
//     confirmPasswordController.dispose();
//
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Create Account',
//         ),
//       ),
//
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(24),
//
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//
//             children: [
//               const SizedBox(height: 20),
//
//               // Title
//               const Text(
//                 'Create your account',
//                 style: TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//
//               const SizedBox(height: 8),
//
//               // Subtitle
//               const Text(
//                 'Enter your information to get started',
//                 style: TextStyle(
//                   color: Colors.grey,
//                   fontSize: 15,
//                 ),
//               ),
//
//               const SizedBox(height: 30),
//
//               // Full Name
//               const Text(
//                 'Full Name',
//                 style: TextStyle(
//                   fontSize: 15,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//
//               const SizedBox(height: 8),
//
//               TextField(
//                 controller: nameController,
//
//                 decoration: InputDecoration(
//                   hintText: 'Enter your full name',
//
//                   prefixIcon: const Icon(
//                     Icons.person_outline,
//                   ),
//
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//               ),
//
//               const SizedBox(height: 20),
//
//               // Email
//               const Text(
//                 'Email',
//                 style: TextStyle(
//                   fontSize: 15,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//
//               const SizedBox(height: 8),
//
//               TextField(
//                 controller: emailController,
//
//                 keyboardType: TextInputType.emailAddress,
//
//                 decoration: InputDecoration(
//                   hintText: 'Enter your email',
//
//                   prefixIcon: const Icon(
//                     Icons.email_outlined,
//                   ),
//
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//               ),
//
//               const SizedBox(height: 20),
//
//               // Password
//               const Text(
//                 'Password',
//                 style: TextStyle(
//                   fontSize: 15,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//
//               const SizedBox(height: 8),
//
//               TextField(
//                 controller: passwordController,
//
//                 obscureText: obscurePassword,
//
//                 decoration: InputDecoration(
//                   hintText: 'Enter your password',
//
//                   prefixIcon: const Icon(
//                     Icons.lock_outline,
//                   ),
//
//                   suffixIcon: IconButton(
//                     onPressed: () {
//                       setState(() {
//                         obscurePassword = !obscurePassword;
//                       });
//                     },
//
//                     icon: Icon(
//                       obscurePassword
//                           ? Icons.visibility_outlined
//                           : Icons.visibility_off_outlined,
//                     ),
//                   ),
//
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//               ),
//
//               const SizedBox(height: 20),
//
//               // Confirm Password
//               const Text(
//                 'Confirm Password',
//                 style: TextStyle(
//                   fontSize: 15,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//
//               const SizedBox(height: 8),
//
//               TextField(
//                 controller: confirmPasswordController,
//
//                 obscureText: obscureConfirmPassword,
//
//                 decoration: InputDecoration(
//                   hintText: 'Confirm your password',
//
//                   prefixIcon: const Icon(
//                     Icons.lock_outline,
//                   ),
//
//                   suffixIcon: IconButton(
//                     onPressed: () {
//                       setState(() {
//                         obscureConfirmPassword =
//                         !obscureConfirmPassword;
//                       });
//                     },
//
//                     icon: Icon(
//                       obscureConfirmPassword
//                           ? Icons.visibility_outlined
//                           : Icons.visibility_off_outlined,
//                     ),
//                   ),
//
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//               ),
//
//               const SizedBox(height: 35),
//
//               // Create Account Button
//               SizedBox(
//                 width: double.infinity,
//                 height: 52,
//
//                 child: ElevatedButton(
//                   onPressed: createAccount,
//
//                   child: const Text(
//                     'Create Account',
//
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//
//               const SizedBox(height: 20),
//
//               // Back to Login
//               Center(
//                 child: TextButton(
//                   onPressed: () {
//                     Navigator.pop(context);
//                   },
//
//                   child: const Text(
//                     'Already have an account? Login',
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }