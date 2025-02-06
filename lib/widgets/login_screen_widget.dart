import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:major_project/utils/app_colors.dart';
import 'package:major_project/controller/auth_controller.dart';
import 'package:major_project/views/forget_password_screen.dart';

class LoginScreenWidget extends StatefulWidget {
  const LoginScreenWidget({super.key});

  @override
  State<LoginScreenWidget> createState() => _LoginScreenWidgetState();
}

class _LoginScreenWidgetState extends State<LoginScreenWidget> {
  final AuthController _authController = Get.put(AuthController());
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _acceptTerms = false;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  void _login() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      Get.snackbar("Error", "All fields are required!");
      return;
    }

    if (!_acceptTerms) {
      Get.snackbar("Error", "You must accept the terms and conditions!");
      return;
    }

    if (password.length != 6) {
      Get.snackbar("Error", "Password must be 6 digits!");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    bool success = await _authController.loginUser(username, password);
    setState(() {
      _isLoading = false;
    });

    if (success) {
      Get.offNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Section
          Container(
            width: Get.width,
            height: Get.height * 0.3,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/mask.png"),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: Text(
                "Log In",
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                "Welcome Back Darwin",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blackColor,
                ),
              ),
            ),
          ),
          // Form Section
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Username",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.blackColor,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                _buildTextField(
                  controller: _usernameController,
                  hintText: "Enter your username",
                  icon: Icons.person,
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Password",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.blackColor,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                _buildTextField(
                  controller: _passwordController,
                  hintText: "Enter your password",
                  icon: Icons.lock,
                  obscureText: !_isPasswordVisible,
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppColors.greenColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Get.to(() => const ForgetPasswordScreen());
                      },
                      child: Text(
                        "Forgot Password?",
                        style: GoogleFonts.poppins(
                          color: AppColors.greenColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
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
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _acceptTerms = !_acceptTerms;
                          });
                        },
                        child: Text(
                          "I accept the terms and conditions",
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.greenColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Continue",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      maxLength: maxLength,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: AppColors.greenColor),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        counterText: "", // Hides the max length counter
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.greenColor),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}









// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:major_project/utils/app_colors.dart';
// import 'package:major_project/controller/auth_controller.dart';
// import 'package:major_project/views/forget_password_screen.dart';

// class LoginScreenWidget extends StatefulWidget {
//   const LoginScreenWidget({Key? key}) : super(key: key);

//   @override
//   State<LoginScreenWidget> createState() => _LoginScreenWidgetState();
// }

// class _LoginScreenWidgetState extends State<LoginScreenWidget> {
//   final AuthController _authController = Get.put(AuthController());
//   final TextEditingController _usernameController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   bool _acceptTerms = false;

//   void _login() async {
//     String username = _usernameController.text.trim();
//     String password = _passwordController.text.trim();

//     if (username.isEmpty || password.isEmpty) {
//       Get.snackbar("Error", "All fields are required!");
//       return;
//     }

//     if (!_acceptTerms) {
//       Get.snackbar("Error", "You must accept the terms and conditions!");
//       return;
//     }

//     if (password.length != 6) {
//       Get.snackbar("Error", "Password must be 6 digits!");
//       return;
//     }

//     bool success = await _authController.loginUser(username, password);
//     if (success) {
//       Get.offNamed('/home');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: Column(
//         children: [
//           Container(
//             width: Get.width,
//             height: Get.height * 0.3,
//             decoration: const BoxDecoration(
//               image: DecorationImage(
//                 image: AssetImage("assets/mask.png"),
//                 fit: BoxFit.cover,
//               ),
//             ),
//             child: Center(
//               child: Text(
//                 "Log In",
//                 style: GoogleFonts.poppins(
//                   fontSize: 32,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 10,),
//           Align(
//             alignment: Alignment.centerLeft,
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20.0),
//               child: Text(
//                 "Welcome Back",
//                 style: GoogleFonts.poppins(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: AppColors.blackColor,
//                 ),
//               ),
//             ),
//           ),
          
//           Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Column(
//               children: [
//                 Align(
//                   alignment: Alignment.centerLeft,
//                   child: Text(
//                     "Username",
//                     style: GoogleFonts.poppins(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                       color: AppColors.blackColor,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 5),
                
//                 const SizedBox(height: 5,),
//                 _buildTextField(
//                   controller: _usernameController,
//                   hintText: "Enter your username",
//                   icon: Icons.person,
//                 ),
//                 const SizedBox(height: 20),
//                 Align(
//                   alignment: Alignment.centerLeft,
//                   child: Text(
//                     "Password",
//                     style: GoogleFonts.poppins(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                       color: AppColors.blackColor,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 5),
//                 _buildTextField(
//                   controller: _passwordController,
//                   hintText: "Enter your password",
//                   icon: Icons.lock,
//                   obscureText: true,
//                   maxLength: 6,
//                   keyboardType: TextInputType.number,
//                 ),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     GestureDetector(
//                       onTap: () {
//                         Get.to(() => const ForgetPasswordScreen());
//                       },
//                       child: Text(
//                         "Forgot Password?",
//                         style: GoogleFonts.poppins(
//                           color: AppColors.greenColor,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ),
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
//                     Expanded(
//                       child: GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             _acceptTerms = !_acceptTerms;
//                           });
//                         },
//                         child: Text(
//                           "I accept the terms and conditions",
//                           style: GoogleFonts.poppins(fontSize: 14),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: _login,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.greenColor,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 50,
//                       vertical: 15,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   child: const Text(
//                     "Continue",
//                     style: TextStyle(fontSize: 18, color: Colors.white),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String hintText,
//     required IconData icon,
//     bool obscureText = false,
//     int? maxLength,
//     TextInputType keyboardType = TextInputType.text,
//   }) {
//     return TextField(
//       controller: controller,
//       obscureText: obscureText,
//       maxLength: maxLength,
//       keyboardType: keyboardType,
//       decoration: InputDecoration(
//         hintText: hintText,
//         prefixIcon: Icon(icon, color: AppColors.greenColor),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         counterText: "", // Hides the max length counter
//         focusedBorder: OutlineInputBorder(
//           borderSide: BorderSide(color: AppColors.greenColor),
//           borderRadius: BorderRadius.circular(10),
//         ),
//       ),
//     );
//   }
// }

     



















// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:major_project/utils/app_colors.dart';
// import 'package:major_project/controller/auth_controller.dart';
// import 'package:major_project/views/forget_password_screen.dart';

// class LoginScreenWidget extends StatefulWidget {
//   const LoginScreenWidget({Key? key}) : super(key: key);

//   @override
//   State<LoginScreenWidget> createState() => _LoginScreenWidgetState();
// }

// class _LoginScreenWidgetState extends State<LoginScreenWidget> {
//   final AuthController _authController = Get.put(AuthController());
//   final TextEditingController _usernameController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   bool _acceptTerms = false;

//   void _login() async {
//      // Ensure cleanup before retrying login
//     FocusScope.of(context).unfocus();
//     setState(() {});

//     String username = _usernameController.text.trim();
//     String password = _passwordController.text.trim();

//     if (username.isEmpty || password.isEmpty) {
//       Get.snackbar("Error", "All fields are required!");
//       return;
//     }

//     if (!_acceptTerms) {
//       Get.snackbar("Error", "You must accept the terms and conditions!");
//       return;
//     }

//     if (password.length != 6) {
//       Get.snackbar("Error", "Password must be 6 digits!");
//       return;
//     }

//     bool success = await _authController.loginUser(username, password);
//     if (success) {
//       Get.offNamed('/home');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: Column(
//         children: [
//           Container(
//             width: Get.width,
//             height: Get.height * 0.3,
//             decoration: const BoxDecoration(
//               image: DecorationImage(
//                 image: AssetImage("assets/mask.png"),
//                 fit: BoxFit.cover,
//               ),
//             ),
//             child: Center(
//               child: Text(
//                 "Log In",
//                 style: GoogleFonts.poppins(
//                   fontSize: 32,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 10,),
//           Align(
//             alignment: Alignment.centerLeft,
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20.0),
//               child: Text(
//                 "Welcome Back",
//                 style: GoogleFonts.poppins(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: AppColors.blackColor,
//                 ),
//               ),
//             ),
//           ),
          
//           Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Column(
//               children: [
//                 Align(
//                   alignment: Alignment.centerLeft,
//                   child: Text(
//                     "Username",
//                     style: GoogleFonts.poppins(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                       color: AppColors.blackColor,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 5),
                
//                 const SizedBox(height: 5,),
//                 _buildTextField(
//                   controller: _usernameController,
//                   hintText: "Enter your username",
//                   icon: Icons.person,
//                 ),
//                 const SizedBox(height: 20),
//                 Align(
//                   alignment: Alignment.centerLeft,
//                   child: Text(
//                     "Password",
//                     style: GoogleFonts.poppins(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                       color: AppColors.blackColor,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 5),
//                 _buildTextField(
//                   controller: _passwordController,
//                   hintText: "Enter your password",
//                   icon: Icons.lock,
//                   obscureText: true,
//                   maxLength: 6,
//                   keyboardType: TextInputType.number,
//                 ),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     GestureDetector(
//                       onTap: () {
//                         Get.to(() => const ForgetPasswordScreen());
//                       },
//                       child: Text(
//                         "Forgot Password?",
//                         style: GoogleFonts.poppins(
//                           color: AppColors.greenColor,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ),
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
//                     Expanded(
//                       child: GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             _acceptTerms = !_acceptTerms;
//                           });
//                         },
//                         child: Text(
//                           "I accept the terms and conditions",
//                           style: GoogleFonts.poppins(fontSize: 14),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: _login,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.greenColor,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 50,
//                       vertical: 15,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   child: const Text(
//                     "Continue",
//                     style: TextStyle(fontSize: 18, color: Colors.white),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String hintText,
//     required IconData icon,
//     bool obscureText = false,
//     int? maxLength,
//     TextInputType keyboardType = TextInputType.text,
//   }) {
//     return TextField(
//       controller: controller,
//       obscureText: obscureText,
//       maxLength: maxLength,
//       keyboardType: keyboardType,
//       decoration: InputDecoration(
//         hintText: hintText,
//         prefixIcon: Icon(icon, color: AppColors.greenColor),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         counterText: "", // Hides the max length counter
//         focusedBorder: OutlineInputBorder(
//           borderSide: BorderSide(color: AppColors.greenColor),
//           borderRadius: BorderRadius.circular(10),
//         ),
//       ),
//     );
//   }
// }

     


     








// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:major_project/utils/app_colors.dart';
// import 'package:major_project/controller/auth_controller.dart';
// import 'package:major_project/views/forget_password_screen.dart';

// class LoginScreenWidget extends StatefulWidget {
//   const LoginScreenWidget({Key? key}) : super(key: key);

//   @override
//   State<LoginScreenWidget> createState() => _LoginScreenWidgetState();
// }

// class _LoginScreenWidgetState extends State<LoginScreenWidget> {
//   final AuthController _authController = Get.put(AuthController());
//   final TextEditingController _usernameController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   bool _acceptTerms = false;

//   void _login() async {
//     String username = _usernameController.text.trim();
//     String password = _passwordController.text.trim();

//     if (username.isEmpty || password.isEmpty) {
//       Get.snackbar("Error", "All fields are required!");
//       return;
//     }

//     if (!_acceptTerms) {
//       Get.snackbar("Error", "You must accept the terms and conditions!");
//       return;
//     }

//     if (password.length != 6) {
//       Get.snackbar("Error", "Password must be 6 digits!");
//       return;
//     }

//     bool success = await _authController.loginUser(username, password);
//     if (success) {
//       Get.offNamed('/home');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: Column(
//         children: [
//           Container(
//             width: Get.width,
//             height: Get.height * 0.3,
//             decoration: const BoxDecoration(
//               image: DecorationImage(
//                 image: AssetImage("assets/mask.png"),
//                 fit: BoxFit.cover,
//               ),
//             ),
//             child: Center(
//               child: Text(
//                 "Log In",
//                 style: GoogleFonts.poppins(
//                   fontSize: 32,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 10,),
//           Align(
//             alignment: Alignment.centerLeft,
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20.0),
//               child: Text(
//                 "Welcome Back",
//                 style: GoogleFonts.poppins(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: AppColors.blackColor,
//                 ),
//               ),
//             ),
//           ),
          
//           Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Column(
//               children: [
//                 Align(
//                   alignment: Alignment.centerLeft,
//                   child: Text(
//                     "Username",
//                     style: GoogleFonts.poppins(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                       color: AppColors.blackColor,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 5),
                
//                 const SizedBox(height: 5,),
//                 _buildTextField(
//                   controller: _usernameController,
//                   hintText: "Enter your username",
//                   icon: Icons.person,
//                 ),
//                 const SizedBox(height: 20),
//                 Align(
//                   alignment: Alignment.centerLeft,
//                   child: Text(
//                     "Password",
//                     style: GoogleFonts.poppins(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                       color: AppColors.blackColor,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 5),
//                 _buildTextField(
//                   controller: _passwordController,
//                   hintText: "Enter your password",
//                   icon: Icons.lock,
//                   obscureText: true,
//                   maxLength: 6,
//                   keyboardType: TextInputType.number,
//                 ),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     GestureDetector(
//                       onTap: () {
//                         Get.to(() => const ForgetPasswordScreen());
//                       },
//                       child: Text(
//                         "Forgot Password?",
//                         style: GoogleFonts.poppins(
//                           color: AppColors.greenColor,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ),
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
//                     Expanded(
//                       child: GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             _acceptTerms = !_acceptTerms;
//                           });
//                         },
//                         child: Text(
//                           "I accept the terms and conditions",
//                           style: GoogleFonts.poppins(fontSize: 14),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: _login,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.greenColor,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 50,
//                       vertical: 15,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   child: const Text(
//                     "Continue",
//                     style: TextStyle(fontSize: 18, color: Colors.white),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String hintText,
//     required IconData icon,
//     bool obscureText = false,
//     int? maxLength,
//     TextInputType keyboardType = TextInputType.text,
//   }) {
//     return TextField(
//       controller: controller,
//       obscureText: obscureText,
//       maxLength: maxLength,
//       keyboardType: keyboardType,
//       decoration: InputDecoration(
//         hintText: hintText,
//         prefixIcon: Icon(icon, color: AppColors.greenColor),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         counterText: "", // Hides the max length counter
//         focusedBorder: OutlineInputBorder(
//           borderSide: BorderSide(color: AppColors.greenColor),
//           borderRadius: BorderRadius.circular(10),
//         ),
//       ),
//     );
//   }
// }

     
