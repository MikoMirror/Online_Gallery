import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();

  bool _isPasswordValid = true;
  bool _doPasswordsMatch = true;
  bool _isEmailValid = true;

  bool _validateEmail(String email) {
    // Simple email validation regex
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            // Registration successful, return to login screen
            Navigator.of(context).pop();
          }
          if (state is AuthError) {
            // Show error snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error)),
            );
            if (state.error.contains('email-already-in-use')) {
              // Show tooltip for existing email
              _showEmailExistsTooltip();
            }
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomTextField(
                  hintText: 'Email',
                  controller: _emailController,
                  errorText: !_isEmailValid ? 'Invalid email format' : null,
                  onChanged: (value) {
                    setState(() {
                      _isEmailValid = _validateEmail(value);
                    });
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  hintText: 'Nickname',
                  controller: _nicknameController,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  hintText: 'Password',
                  controller: _passwordController,
                  obscureText: true,
                  errorText: !_isPasswordValid
                      ? 'Password must be at least 8 characters'
                      : null,
                  onChanged: (value) {
                    setState(() {
                      _isPasswordValid = value.length >= 8;
                      _doPasswordsMatch =
                          value == _confirmPasswordController.text;
                    });
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  hintText: 'Confirm Password',
                  controller: _confirmPasswordController,
                  obscureText: true,
                  errorText:
                      !_doPasswordsMatch ? 'Passwords do not match' : null,
                  onChanged: (value) {
                    setState(() {
                      _doPasswordsMatch = value == _passwordController.text;
                    });
                  },
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: 'Register',
                  onPressed: (_isPasswordValid && _doPasswordsMatch && _isEmailValid)
                      ? () {
                          BlocProvider.of<AuthBloc>(context).add(
                            SignUpRequested(
                              _emailController.text.trim(),
                              _passwordController.text,
                              _nicknameController.text,
                            ),
                          );
                        }
                      : null,
                ),
                if (state is AuthLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEmailExistsTooltip() {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset topLeft = button.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
          topLeft.dx, topLeft.dy, topLeft.dx + 200, topLeft.dy + 100),
      items: [
        PopupMenuItem(
          child: Text('An account with this email already exists.'),
          enabled: false,
        ),
      ],
    );
  }
}