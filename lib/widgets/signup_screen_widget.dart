import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for input formatters
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:major_project/utils/app_colors.dart';
import 'package:major_project/controller/auth_controller.dart';

class SignupScreenWidget extends StatefulWidget {
  const SignupScreenWidget({Key? key}) : super(key: key);

  @override
  State<SignupScreenWidget> createState() => _SignupScreenWidgetState();
}

class _SignupScreenWidgetState extends State<SignupScreenWidget> {
  final AuthController _authController = Get.put(AuthController());

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _rePasswordController = TextEditingController();

  bool _acceptTerms = false;

  void _signup() {
    String name = _nameController.text.trim();
    String mobile = _mobileController.text.trim();
    String email = _emailController.text.trim();
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();
    String rePassword = _rePasswordController.text.trim();

    if (name.isEmpty) {
      Get.snackbar("Error", "Name cannot be empty");
      return;
    }
    if (!RegExp(r"^\d{10}$").hasMatch(mobile)) {
      Get.snackbar("Error", "Enter a valid 10-digit mobile number");
      return;
    }
    if (!RegExp(r"^[a-zA-Z0-9._-]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email)) {
      Get.snackbar("Error", "Enter a valid email address");
      return;
    }
    if (username.isEmpty) {
      Get.snackbar("Error", "Username cannot be empty");
      return;
    }
    if (!RegExp(r"^\d{6}$").hasMatch(password)) {
      Get.snackbar("Error", "Password must be a 6-digit number");
      return;
    }
    if (password != rePassword) {
      Get.snackbar("Error", "Passwords do not match");
      return;
    }
    if (!_acceptTerms) {
      Get.snackbar("Error", "You must accept the terms and conditions");
      return;
    }

    // Trigger Firebase Authentication and Firestore write
    _authController.registerUser(
      name: name,
      mobile: mobile,
      email: email,
      username: username,
      password: password,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Intro Section
          Container(
            width: Get.width,
            height: Get.height * 0.2,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/mask.png"),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: Text(
                "Sign Up",
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildTextField("Name", "Enter your full name", Icons.person,
                    _nameController),
                const SizedBox(height: 15),
                _buildTextField(
                  "Mobile Number",
                  "Enter 10-digit number",
                  Icons.phone,
                  _mobileController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
                const SizedBox(height: 15),
                _buildTextField("Email", "Enter your email", Icons.email,
                    _emailController,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 15),
                _buildTextField(
                    "Username", "Choose a username", Icons.person_outline,
                    _usernameController),
                const SizedBox(height: 15),
                _buildTextField(
                  "Password",
                  "6-digit pin",
                  Icons.lock,
                  _passwordController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  "Re-enter Password",
                  "Confirm password",
                  Icons.lock_outline,
                  _rePasswordController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (value) {
                        setState(() {
                          _acceptTerms = value!;
                        });
                      },
                      activeColor: AppColors.greenColor,
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _acceptTerms = !_acceptTerms;
                        });
                      },
                      child: const Text(
                        "I accept the terms and conditions",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.greenColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                  ),
                  child: const Text("Sign Up",
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hintText,
    IconData icon,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      inputFormatters: inputFormatters, // Apply input formatters here
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: AppColors.greenColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}









// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; // Import for input formatters
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:major_project/utils/app_colors.dart';
// import 'package:major_project/controller/auth_controller.dart';

// class SignupScreenWidget extends StatefulWidget {
//   const SignupScreenWidget({Key? key}) : super(key: key);

//   @override
//   State<SignupScreenWidget> createState() => _SignupScreenWidgetState();
// }

// class _SignupScreenWidgetState extends State<SignupScreenWidget> {
//   final AuthController _authController = Get.put(AuthController());

//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _mobileController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _usernameController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final TextEditingController _rePasswordController = TextEditingController();

//   bool _acceptTerms = false;

//   void _signup() {
//     String name = _nameController.text.trim();
//     String mobile = _mobileController.text.trim();
//     String email = _emailController.text.trim();
//     String username = _usernameController.text.trim();
//     String password = _passwordController.text.trim();
//     String rePassword = _rePasswordController.text.trim();

//     if (name.isEmpty) {
//       Get.snackbar("Error", "Name cannot be empty");
//       return;
//     }
//     if (!RegExp(r"^\d{10}$").hasMatch(mobile)) {
//       Get.snackbar("Error", "Enter a valid 10-digit mobile number");
//       return;
//     }
//     if (!RegExp(r"^[a-zA-Z0-9._-]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email)) {
//       Get.snackbar("Error", "Enter a valid email address");
//       return;
//     }
//     if (username.isEmpty) {
//       Get.snackbar("Error", "Username cannot be empty");
//       return;
//     }
//     if (!RegExp(r"^\d{6}$").hasMatch(password)) {
//       Get.snackbar("Error", "Password must be a 6-digit number");
//       return;
//     }
//     if (password != rePassword) {
//       Get.snackbar("Error", "Passwords do not match");
//       return;
//     }
//     if (!_acceptTerms) {
//       Get.snackbar("Error", "You must accept the terms and conditions");
//       return;
//     }

//     // Trigger Firebase Authentication and Firestore write
//     _authController.registerUser(
//       name: name,
//       mobile: mobile,
//       email: email,
//       username: username,
//       password: password,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: Column(
//         children: [
//           // Intro Section
//           Container(
//             width: Get.width,
//             height: Get.height * 0.1,
//             decoration: const BoxDecoration(
//               image: DecorationImage(
//                 image: AssetImage("assets/mask.png"),
//                 fit: BoxFit.cover,
//               ),
//             ),
//             child: Center(
//               child: Text(
//                 "Sign Up",
//                 style: GoogleFonts.poppins(
//                   fontSize: 40,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Column(
//               children: [
//                 _buildTextField("Name", "Enter your full name", Icons.person,
//                     _nameController),
//                 const SizedBox(height: 15),
//                 _buildTextField(
//                   "Mobile Number",
//                   "Enter 10-digit number",
//                   Icons.phone,
//                   _mobileController,
//                   keyboardType: TextInputType.phone,
//                   inputFormatters: [
//                     FilteringTextInputFormatter.digitsOnly,
//                     LengthLimitingTextInputFormatter(10),
//                   ],
//                 ),
//                 const SizedBox(height: 15),
//                 _buildTextField("Email", "Enter your email", Icons.email,
//                     _emailController,
//                     keyboardType: TextInputType.emailAddress),
//                 const SizedBox(height: 15),
//                 _buildTextField(
//                     "Username", "Choose a username", Icons.person_outline,
//                     _usernameController),
//                 const SizedBox(height: 15),
//                 _buildTextField(
//                   "Password",
//                   "6-digit pin",
//                   Icons.lock,
//                   _passwordController,
//                   obscureText: true,
//                   keyboardType: TextInputType.number,
//                   inputFormatters: [
//                     FilteringTextInputFormatter.digitsOnly,
//                     LengthLimitingTextInputFormatter(6),
//                   ],
//                 ),
//                 const SizedBox(height: 15),
//                 _buildTextField(
//                   "Re-enter Password",
//                   "Confirm password",
//                   Icons.lock_outline,
//                   _rePasswordController,
//                   obscureText: true,
//                   keyboardType: TextInputType.number,
//                   inputFormatters: [
//                     FilteringTextInputFormatter.digitsOnly,
//                     LengthLimitingTextInputFormatter(6),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//                 Row(
//                   children: [
//                     Checkbox(
//                       value: _acceptTerms,
//                       onChanged: (value) {
//                         setState(() {
//                           _acceptTerms = value!;
//                         });
//                       },
//                       activeColor: AppColors.greenColor,
//                     ),
//                     const Text("I accept the terms and conditions"),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: _signup,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.greenColor,
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 50, vertical: 15),
//                   ),
//                   child: const Text("Sign Up",
//                       style: TextStyle(fontSize: 18, color: Colors.white)),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTextField(
//     String label,
//     String hintText,
//     IconData icon,
//     TextEditingController controller, {
//     TextInputType keyboardType = TextInputType.text,
//     bool obscureText = false,
//     List<TextInputFormatter>? inputFormatters,
//   }) {
//     return TextField(
//       controller: controller,
//       keyboardType: keyboardType,
//       obscureText: obscureText,
//       inputFormatters: inputFormatters, // Apply input formatters here
//       decoration: InputDecoration(
//         labelText: label,
//         hintText: hintText,
//         prefixIcon: Icon(icon, color: AppColors.greenColor),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }
// }



















// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; // Import for input formatters
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:major_project/utils/app_colors.dart';
// import 'package:major_project/controller/auth_controller.dart';

// class SignupScreenWidget extends StatefulWidget {
//   const SignupScreenWidget({Key? key}) : super(key: key);

//   @override
//   State<SignupScreenWidget> createState() => _SignupScreenWidgetState();
// }

// class _SignupScreenWidgetState extends State<SignupScreenWidget> {
//   final AuthController _authController = Get.put(AuthController());

//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _mobileController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _usernameController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final TextEditingController _rePasswordController = TextEditingController();

//   bool _acceptTerms = false;

//   void _signup() {
//     String name = _nameController.text.trim();
//     String mobile = _mobileController.text.trim();
//     String email = _emailController.text.trim();
//     String username = _usernameController.text.trim();
//     String password = _passwordController.text.trim();
//     String rePassword = _rePasswordController.text.trim();

//     if (name.isEmpty) {
//       Get.snackbar("Error", "Name cannot be empty");
//       return;
//     }
//     if (!RegExp(r"^\d{10}$").hasMatch(mobile)) {
//       Get.snackbar("Error", "Enter a valid 10-digit mobile number");
//       return;
//     }
//     if (!RegExp(r"^[a-zA-Z0-9._-]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email)) {
//       Get.snackbar("Error", "Enter a valid email address");
//       return;
//     }
//     if (username.isEmpty) {
//       Get.snackbar("Error", "Username cannot be empty");
//       return;
//     }
//     if (!RegExp(r"^\d{6}$").hasMatch(password)) {
//       Get.snackbar("Error", "Password must be a 6-digit number");
//       return;
//     }
//     if (password != rePassword) {
//       Get.snackbar("Error", "Passwords do not match");
//       return;
//     }
//     if (!_acceptTerms) {
//       Get.snackbar("Error", "You must accept the terms and conditions");
//       return;
//     }

//     // Trigger Firebase Authentication and Firestore write
//     _authController.registerUser(
//       name: name,
//       mobile: mobile,
//       email: email,
//       username: username,
//       password: password,
//     );

//     // Navigate to the setup profile screen after registration
//     Get.toNamed('/setupProfileScreen');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: Column(
//         children: [
//           // Intro Section
//           Container(
//             width: Get.width,
//             height: Get.height * 0.1,
//             decoration: const BoxDecoration(
//               image: DecorationImage(
//                 image: AssetImage("assets/mask.png"),
//                 fit: BoxFit.cover,
//               ),
//             ),
//             child: Center(
//               child: Text(
//                 "Sign Up",
//                 style: GoogleFonts.poppins(
//                   fontSize: 40,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Column(
//               children: [
//                 _buildTextField("Name", "Enter your full name", Icons.person,
//                     _nameController),
//                 const SizedBox(height: 15),
//                 _buildTextField(
//                   "Mobile Number",
//                   "Enter 10-digit number",
//                   Icons.phone,
//                   _mobileController,
//                   keyboardType: TextInputType.phone,
//                   inputFormatters: [
//                     FilteringTextInputFormatter.digitsOnly,
//                     LengthLimitingTextInputFormatter(10),
//                   ],
//                 ),
//                 const SizedBox(height: 15),
//                 _buildTextField("Email", "Enter your email", Icons.email,
//                     _emailController,
//                     keyboardType: TextInputType.emailAddress),
//                 const SizedBox(height: 15),
//                 _buildTextField(
//                     "Username", "Choose a username", Icons.person_outline,
//                     _usernameController),
//                 const SizedBox(height: 15),
//                 _buildTextField(
//                   "Password",
//                   "6-digit pin",
//                   Icons.lock,
//                   _passwordController,
//                   obscureText: true,
//                   keyboardType: TextInputType.number,
//                   inputFormatters: [
//                     FilteringTextInputFormatter.digitsOnly,
//                     LengthLimitingTextInputFormatter(6),
//                   ],
//                 ),
//                 const SizedBox(height: 15),
//                 _buildTextField(
//                   "Re-enter Password",
//                   "Confirm password",
//                   Icons.lock_outline,
//                   _rePasswordController,
//                   obscureText: true,
//                   keyboardType: TextInputType.number,
//                   inputFormatters: [
//                     FilteringTextInputFormatter.digitsOnly,
//                     LengthLimitingTextInputFormatter(6),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//                 Row(
//                   children: [
//                     Checkbox(
//                       value: _acceptTerms,
//                       onChanged: (value) {
//                         setState(() {
//                           _acceptTerms = value!;
//                         });
//                       },
//                       activeColor: AppColors.greenColor,
//                     ),
//                     const Text("I accept the terms and conditions"),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: _signup,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.greenColor,
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 50, vertical: 15),
//                   ),
//                   child: const Text("Sign Up",
//                       style: TextStyle(fontSize: 18, color: Colors.white)),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTextField(
//     String label,
//     String hintText,
//     IconData icon,
//     TextEditingController controller, {
//     TextInputType keyboardType = TextInputType.text,
//     bool obscureText = false,
//     List<TextInputFormatter>? inputFormatters,
//   }) {
//     return TextField(
//       controller: controller,
//       keyboardType: keyboardType,
//       obscureText: obscureText,
//       inputFormatters: inputFormatters, // Apply input formatters here
//       decoration: InputDecoration(
//         labelText: label,
//         hintText: hintText,
//         prefixIcon: Icon(icon, color: AppColors.greenColor),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }
// }














// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; // Import for input formatters
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:major_project/utils/app_colors.dart';
// import 'package:major_project/controller/auth_controller.dart';

// class SignupScreenWidget extends StatefulWidget {
//   const SignupScreenWidget({Key? key}) : super(key: key);

//   @override
//   State<SignupScreenWidget> createState() => _SignupScreenWidgetState();
// }

// class _SignupScreenWidgetState extends State<SignupScreenWidget> {
//   final AuthController _authController = Get.put(AuthController());

//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _mobileController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _usernameController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final TextEditingController _rePasswordController = TextEditingController();

//   bool _acceptTerms = false;

//   void _signup() {
//     String name = _nameController.text.trim();
//     String mobile = _mobileController.text.trim();
//     String email = _emailController.text.trim();
//     String username = _usernameController.text.trim();
//     String password = _passwordController.text.trim();
//     String rePassword = _rePasswordController.text.trim();

//     if (name.isEmpty) {
//       Get.snackbar("Error", "Name cannot be empty");
//       return;
//     }
//     if (!RegExp(r"^\d{10}$").hasMatch(mobile)) {
//       Get.snackbar("Error", "Enter a valid 10-digit mobile number");
//       return;
//     }
//     if (!RegExp(r"^[a-zA-Z0-9._-]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email)) {
//       Get.snackbar("Error", "Enter a valid email address");
//       return;
//     }
//     if (username.isEmpty) {
//       Get.snackbar("Error", "Username cannot be empty");
//       return;
//     }
//     if (!RegExp(r"^\d{6}$").hasMatch(password)) {
//       Get.snackbar("Error", "Password must be a 6-digit number");
//       return;
//     }
//     if (password != rePassword) {
//       Get.snackbar("Error", "Passwords do not match");
//       return;
//     }
//     if (!_acceptTerms) {
//       Get.snackbar("Error", "You must accept the terms and conditions");
//       return;
//     }

//     // Trigger Firebase Authentication and Firestore write
//     _authController.registerUser(
//       name: name,
//       mobile: mobile,
//       email: email,
//       username: username,
//       password: password,
//     );

//     // Navigate to the setup profile screen after registration
//     Get.toNamed('/setupProfileScreen');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: Column(
//         children: [
//           // Intro Section
//           Container(
//             width: Get.width,
//             height: Get.height * 0.1,
//             decoration: const BoxDecoration(
//               image: DecorationImage(
//                 image: AssetImage("assets/mask.png"),
//                 fit: BoxFit.cover,
//               ),
//             ),
//             child: Center(
//               child: Text(
//                 "Sign Up",
//                 style: GoogleFonts.poppins(
//                   fontSize: 40,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Column(
//               children: [
//                 _buildTextField("Name", "Enter your full name", Icons.person,
//                     _nameController),
//                 const SizedBox(height: 15),
//                 _buildTextField(
//                   "Mobile Number",
//                   "Enter 10-digit number",
//                   Icons.phone,
//                   _mobileController,
//                   keyboardType: TextInputType.phone,
//                   inputFormatters: [
//                     FilteringTextInputFormatter.digitsOnly,
//                     LengthLimitingTextInputFormatter(10),
//                   ],
//                 ),
//                 const SizedBox(height: 15),
//                 _buildTextField("Email", "Enter your email", Icons.email,
//                     _emailController,
//                     keyboardType: TextInputType.emailAddress),
//                 const SizedBox(height: 15),
//                 _buildTextField(
//                     "Username", "Choose a username", Icons.person_outline,
//                     _usernameController),
//                 const SizedBox(height: 15),
//                 _buildTextField(
//                   "Password",
//                   "6-digit pin",
//                   Icons.lock,
//                   _passwordController,
//                   obscureText: true,
//                   keyboardType: TextInputType.number,
//                   inputFormatters: [
//                     FilteringTextInputFormatter.digitsOnly,
//                     LengthLimitingTextInputFormatter(6),
//                   ],
//                 ),
//                 const SizedBox(height: 15),
//                 _buildTextField(
//                   "Re-enter Password",
//                   "Confirm password",
//                   Icons.lock_outline,
//                   _rePasswordController,
//                   obscureText: true,
//                   keyboardType: TextInputType.number,
//                   inputFormatters: [
//                     FilteringTextInputFormatter.digitsOnly,
//                     LengthLimitingTextInputFormatter(6),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//                 Row(
//                   children: [
//                     Checkbox(
//                       value: _acceptTerms,
//                       onChanged: (value) {
//                         setState(() {
//                           _acceptTerms = value!;
//                         });
//                       },
//                       activeColor: AppColors.greenColor,
//                     ),
//                     const Text("I accept the terms and conditions"),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: _signup,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.greenColor,
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 50, vertical: 15),
//                   ),
//                   child: const Text("Sign Up",
//                       style: TextStyle(fontSize: 18, color: Colors.white)),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTextField(
//     String label,
//     String hintText,
//     IconData icon,
//     TextEditingController controller, {
//     TextInputType keyboardType = TextInputType.text,
//     bool obscureText = false,
//     List<TextInputFormatter>? inputFormatters,
//   }) {
//     return TextField(
//       controller: controller,
//       keyboardType: keyboardType,
//       obscureText: obscureText,
//       inputFormatters: inputFormatters, // Apply input formatters here
//       decoration: InputDecoration(
//         labelText: label,
//         hintText: hintText,
//         prefixIcon: Icon(icon, color: AppColors.greenColor),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }
// }









// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; // Import for input formatters
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:major_project/utils/app_colors.dart';
// import 'package:major_project/controller/auth_controller.dart';

// class SignupScreenWidget extends StatefulWidget {
//   const SignupScreenWidget({Key? key}) : super(key: key);

//   @override
//   State<SignupScreenWidget> createState() => _SignupScreenWidgetState();
// }

// class _SignupScreenWidgetState extends State<SignupScreenWidget> {
//   final AuthController _authController = Get.put(AuthController());

//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _mobileController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _usernameController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final TextEditingController _rePasswordController = TextEditingController();

//   bool _acceptTerms = false;

//   void _signup() {
//     String name = _nameController.text.trim();
//     String mobile = _mobileController.text.trim();
//     String email = _emailController.text.trim();
//     String username = _usernameController.text.trim();
//     String password = _passwordController.text.trim();
//     String rePassword = _rePasswordController.text.trim();

//     if (name.isEmpty) {
//       Get.snackbar("Error", "Name cannot be empty");
//       return;
//     }
//     if (!RegExp(r"^\d{10}$").hasMatch(mobile)) {
//       Get.snackbar("Error", "Enter a valid 10-digit mobile number");
//       return;
//     }
//     if (!RegExp(r"^[a-zA-Z0-9._-]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email)) {
//       Get.snackbar("Error", "Enter a valid email address");
//       return;
//     }
//     if (username.isEmpty) {
//       Get.snackbar("Error", "Username cannot be empty");
//       return;
//     }
//     if (!RegExp(r"^\d{6}$").hasMatch(password)) {
//       Get.snackbar("Error", "Password must be a 6-digit number");
//       return;
//     }
//     if (password != rePassword) {
//       Get.snackbar("Error", "Passwords do not match");
//       return;
//     }
//     if (!_acceptTerms) {
//       Get.snackbar("Error", "You must accept the terms and conditions");
//       return;
//     }

//     // Trigger Firebase Authentication and Firestore write
//     _authController.registerUser(
//       name: name,
//       mobile: mobile,
//       email: email,
//       username: username,
//       password: password,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: Column(
//         children: [
//           // Intro Section
//           Container(
//             width: Get.width,
//             height: Get.height * 0.1,
//             decoration: const BoxDecoration(
//               image: DecorationImage(
//                 image: AssetImage("assets/mask.png"),
//                 fit: BoxFit.cover,
//               ),
//             ),
//             child: Center(
//               child: Text(
//                 "Sign Up",
//                 style: GoogleFonts.poppins(
//                   fontSize: 40,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Column(
//               children: [
//                 _buildTextField("Name", "Enter your full name", Icons.person,
//                     _nameController),
//                 const SizedBox(height: 15),
//                 _buildTextField(
//                   "Mobile Number",
//                   "Enter 10-digit number",
//                   Icons.phone,
//                   _mobileController,
//                   keyboardType: TextInputType.phone,
//                   inputFormatters: [
//                     FilteringTextInputFormatter.digitsOnly,
//                     LengthLimitingTextInputFormatter(10),
//                   ],
//                 ),
//                 const SizedBox(height: 15),
//                 _buildTextField("Email", "Enter your email", Icons.email,
//                     _emailController,
//                     keyboardType: TextInputType.emailAddress),
//                 const SizedBox(height: 15),
//                 _buildTextField(
//                     "Username", "Choose a username", Icons.person_outline,
//                     _usernameController),
//                 const SizedBox(height: 15),
//                 _buildTextField(
//                   "Password",
//                   "6-digit pin",
//                   Icons.lock,
//                   _passwordController,
//                   obscureText: true,
//                   keyboardType: TextInputType.number,
//                   inputFormatters: [
//                     FilteringTextInputFormatter.digitsOnly,
//                     LengthLimitingTextInputFormatter(6),
//                   ],
//                 ),
//                 const SizedBox(height: 15),
//                 _buildTextField(
//                   "Re-enter Password",
//                   "Confirm password",
//                   Icons.lock_outline,
//                   _rePasswordController,
//                   obscureText: true,
//                   keyboardType: TextInputType.number,
//                   inputFormatters: [
//                     FilteringTextInputFormatter.digitsOnly,
//                     LengthLimitingTextInputFormatter(6),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//                 Row(
//                   children: [
//                     Checkbox(
//                       value: _acceptTerms,
//                       onChanged: (value) {
//                         setState(() {
//                           _acceptTerms = value!;
//                         });
//                       },
//                       activeColor: AppColors.greenColor,
//                     ),
//                     const Text("I accept the terms and conditions"),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: _signup,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.greenColor,
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 50, vertical: 15),
//                   ),
//                   child: const Text("Sign Up",
//                       style: TextStyle(fontSize: 18, color: Colors.white)),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTextField(
//     String label,
//     String hintText,
//     IconData icon,
//     TextEditingController controller, {
//     TextInputType keyboardType = TextInputType.text,
//     bool obscureText = false,
//     List<TextInputFormatter>? inputFormatters,
//   }) {
//     return TextField(
//       controller: controller,
//       keyboardType: keyboardType,
//       obscureText: obscureText,
//       inputFormatters: inputFormatters, // Apply input formatters here
//       decoration: InputDecoration(
//         labelText: label,
//         hintText: hintText,
//         prefixIcon: Icon(icon, color: AppColors.greenColor),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }
// }















