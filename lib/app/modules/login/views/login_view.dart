import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import 'package:get/get.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/env.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:podium/widgets/textField/textFieldRounded.dart';

import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormBuilderState>();
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            child: FormBuilder(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 200,
                    child: Assets.images.logo.image(),
                  ),
                  Text('Welcome to',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.normal,
                      )),
                  Text(
                    'Podium',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  space10,
                  FormBuilderField(
                    builder: (FormFieldState<String?> field) {
                      return Input(
                        hintText: 'Email',
                        onChanged: (value) => controller.email.value = value,
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          FormBuilderValidators.email(),
                        ]),
                      );
                    },
                    name: 'email',
                  ),
                  space10,
                  FormBuilderField(
                    builder: (FormFieldState<String?> field) {
                      return Input(
                        onChanged: (value) => controller.password.value = value,
                        hintText: 'Password',
                        obscureText: true,
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          FormBuilderValidators.minLength(6),
                        ]),
                      );
                    },
                    name: 'password',
                  ),
                  space10,
                  Obx(
                    () {
                      final loading = controller.isLoggingIn.value;
                      final isAutoLoggingIn = controller.$isAutoLoggingIn.value;
                      return Button(
                        loading: loading || isAutoLoggingIn,
                        type: ButtonType.gradient,
                        blockButton: true,
                        onPressed: () {
                          final re = _formKey.currentState?.saveAndValidate();
                          if (re == true) {
                            controller.login();
                          }
                        },
                        text: 'LOGIN',
                      );
                    },
                  ),
                  space10,
                  Button(
                    size: ButtonSize.MEDIUM,
                    onPressed: () {
                      Navigate.to(
                        type: NavigationTypes.toNamed,
                        route: Routes.SIGNUP,
                      );
                    },
                    text: 'CREATE ACCOUNT',
                    type: ButtonType.transparent,
                  ),
                  space10,
                  Text(
                    "Version: " + Env.VERSION,
                    style: const TextStyle(
                      color: ColorName.greyText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
