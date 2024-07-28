import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';

import 'package:podium/app/modules/signup/controllers/signup_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:podium/widgets/textField/textFieldRounded.dart';

class SignupView extends GetView<SignUpController> {
  const SignupView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormBuilderState>();
    return Scaffold(
      appBar: defaultAppBar,
      body: Center(
          child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FormBuilder(
              key: _formKey,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      controller.pickImage();
                    },
                    child: Obx(
                      () {
                        final selectedFile = controller.fileLocalAddress.value;
                        final error = controller.avatarSelectError.value;
                        return Column(
                          children: [
                            GFAvatar(
                              backgroundImage: selectedFile == ''
                                  ? NetworkImage(
                                      'https://cdn.pixabay.com/photo/2016/08/08/09/17/avatar-1577909_960_720.png')
                                  : FileImage(File(selectedFile)),
                              shape: GFAvatarShape.circle,
                              radius: 50.0,
                            ),
                            if (error.isNotEmpty)
                              Text(
                                error,
                                style: TextStyle(color: Colors.red),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  space10,
                  FormBuilderField(
                    builder: (FormFieldState<String?> field) {
                      return Input(
                        hintText: 'Full Name',
                        onChanged: (value) => controller.fullName.value = value,
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                        ]),
                      );
                    },
                    name: 'fullName',
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
                  FormBuilderField(
                    builder: (FormFieldState<String?> field) {
                      return Obx(() {
                        final passwordValue = controller.password.value;
                        return Input(
                          onChanged: (value) =>
                              controller.password.value = value,
                          hintText: 'confirm Password',
                          obscureText: true,
                          validator: (value) {
                            if (value == '') {
                              if (passwordValue == '') {
                                return 'Please enter password first';
                              } else {
                                return 'Please enter confirm password';
                              }
                            }
                            return passwordValue != value
                                ? 'not equal to entered Password'
                                : null;
                          },
                        );
                      });
                    },
                    name: 'confirmPassword',
                  ),
                ],
              ),
            ),
            space10,
            Obx(() {
              final loading = controller.isSigningUp.value;
              final imageAddress = controller.fileLocalAddress.value;
              return Button(
                loading: loading,
                text: 'SIGN UP',
                blockButton: true,
                type: ButtonType.gradient,
                onPressed: () {
                  if (imageAddress == '') {
                    controller.avatarSelectError.value =
                        'Please select an avatar';
                  }
                  final re = _formKey.currentState?.saveAndValidate();
                  if (re == true && imageAddress != '') {
                    controller.signUp();
                  }
                },
              );
            }),
            space10,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already have an account?'),
                Button(
                  textColor: ColorName.primaryBlue,
                  onPressed: () {
                    Navigate.to(
                      type: NavigationTypes.toNamed,
                      route: Routes.LOGIN,
                    );
                  },
                  text: 'LOGIN',
                  type: ButtonType.transparent,
                ),
              ],
            ),
          ],
        ),
      )),
    );
  }
}
