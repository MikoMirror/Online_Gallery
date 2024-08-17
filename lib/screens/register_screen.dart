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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            // Registration successful, return to login screen
            Navigator.of(context).pop();
          }
          if (state is AuthError) {
            if (state.error.contains('email-already-in-use')) {
              // Show tooltip for existing email
              _showEmailExistsTooltip();
            } else {
              // Show error snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error)),
              );
            }
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomTextField(
                    hintText: 'Email',
                    controller: _emailController,
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
                    onPressed: (_isPasswordValid && _doPasswordsMatch)
                        ? () {
                            BlocProvider.of<AuthBloc>(context).add(
                              SignUpRequested(
                                _emailController.text,
                                _passwordController.text,
                                _nicknameController.text,
                              ),
                            );
                          }
                        : null,
                  ),
                ],
              ),
            );
          },
        ),
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