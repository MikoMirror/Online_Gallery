import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';
import 'register_screen.dart';
import 'main_screen.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({Key? key}) : super(key: key);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: BlocListener<AuthBloc, AuthState>(
        listener: _authStateListener,
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return _buildLoginForm(context);
          },
        ),
      ),
    );
  }

  void _authStateListener(BuildContext context, AuthState state) {
    if (state is Authenticated) {
      _navigateToMainScreen(context, state.user);
    }
    if (state is AuthError) {
      _showErrorSnackBar(context, state.error);
    }
  }

  void _navigateToMainScreen(BuildContext context, user) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => MainScreen(user: user)),
    );
  }

  void _showErrorSnackBar(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
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
            hintText: 'Password',
            controller: _passwordController,
            obscureText: true,
          ),
          const SizedBox(height: 20),
          CustomButton(
            text: 'Login',
            onPressed: () => _attemptLogin(context),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => _navigateToRegisterScreen(context),
            child: const Text('Don\'t have an account? Register'),
          ),
        ],
      ),
    );
  }

  void _attemptLogin(BuildContext context) {
    BlocProvider.of<AuthBloc>(context).add(
      SignInRequested(
        _emailController.text,
        _passwordController.text,
      ),
    );
  }

  void _navigateToRegisterScreen(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => RegisterScreen(),
    ));
  }
}