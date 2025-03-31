import 'package:flutter/material.dart';
import 'package:photodiary/main.dart';
import 'auth_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final emailFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();
  final confirmPasswordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    emailFocusNode.addListener(() {
      setState(() {});
    });
    passwordFocusNode.addListener(() {
      setState(() {});
    });
    confirmPasswordFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  // Switching between login and sign-up screens
  void toggleView() {
    setState(() {
      isLogin = !isLogin;
    });
  }

  // Input wizet : typeName - email, password, confirmpassword
  Padding input(String typeName, IconData icon,
      TextEditingController controller, FocusNode focusNode) {
    bool obscure = typeName.toLowerCase() == "password" ||
        typeName.toLowerCase() == "confirm password";
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10), // 둥근 모서리 클리핑
        child: Container(
          color: Colors.white,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscure,
            style: const TextStyle(fontSize: 18, color: Colors.black),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: focusNode.hasFocus
                    ? const Color(0xffE9E9E0)
                    : const Color(0xffc5c5c5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              hintText: typeName,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xffc5c5c5), width: 2.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFF4387C2), width: 2.0),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // login and sign-up text messages
  Padding accountToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: toggleView,
            child: Text(
              isLogin ? "Create Account?" : "Already Member?",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  // common buttun wizet (Modify behavior depending on whether it's login or sign-up)
  Padding actionButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Container(
        width: double.infinity,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF4387C2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: GestureDetector(
          onTap: () async {
            try {
              if (isLogin) {
                // If log-in page?
                await AuthenticationRemote()
                    .login(emailController.text, passwordController.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Login successful."),
                    backgroundColor: Colors.green,
                  ),
                );
                // If log-in success? move to MainScreen page
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MainScreen()),
                );
              } else {
                // If sign-up page? show error message
                if (passwordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Passwords do not match."),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                await AuthenticationRemote().register(emailController.text,
                    passwordController.text, confirmPasswordController.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Account creation successful."),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Error: ${e.toString()}"),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Text(
            isLogin ? "Log In" : "Sign Up",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffE9E9E0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // display Image
              Container(
                width: double.infinity,
                height: 300,
                decoration: const BoxDecoration(
                  color: Color(0xffE9E9E0),
                  image: DecorationImage(
                    image: AssetImage('images/photo_diary_header.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // ID input box
              input("Email", Icons.email, emailController, emailFocusNode),
              const SizedBox(height: 10),
              // password input box
              input("Password", Icons.password, passwordController,
                  passwordFocusNode),
              const SizedBox(height: 10),
              // password confirm input box
              if (!isLogin)
                input("Confirm Password", Icons.password,
                    confirmPasswordController, confirmPasswordFocusNode),
              const SizedBox(height: 10),
              // button wizet (login/signup)
              actionButton(),
              const SizedBox(height: 20),
              // Text Message (Create Account? / Alread Member?)
              accountToggle(),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
