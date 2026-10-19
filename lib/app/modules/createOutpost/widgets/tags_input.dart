import 'dart:math';

import 'package:flutter/material.dart';
import 'package:podium/utils/palette.dart';
import 'package:textfield_tags/textfield_tags.dart';

/*
 * Dynamic Tags 
 */
class ButtonData {
  final Color buttonColor;
  final String emoji;
  const ButtonData(this.buttonColor, this.emoji);
}

class DynamicTags extends StatefulWidget {
  final Function(List<String>) onTagsChanged;
  const DynamicTags({
    Key? key,
    required this.onTagsChanged,
  }) : super(key: key);

  @override
  State<DynamicTags> createState() => _DynamicTagsState();
}

class _DynamicTagsState extends State<DynamicTags> {
  late DynamicTagController<DynamicTagData<ButtonData>> _dynamicTagController;

  @override
  void dispose() {
    super.dispose();
    _dynamicTagController.dispose();
  }

  @override
  void initState() {
    super.initState();
    _dynamicTagController = DynamicTagController<DynamicTagData<ButtonData>>();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxChipsWidth = constraints.maxWidth * 0.72;
        return TextFieldTags<DynamicTagData<ButtonData>>(
          textfieldTagsController: _dynamicTagController,
          initialTags: const [],
          textSeparators: const [' ', ',', '.', ';', '\n'],
          letterCase: LetterCase.normal,
          inputFieldBuilder: (context, inputFieldValues) {
            final hasTags = inputFieldValues.tags.isNotEmpty;
            return TextField(
              controller: inputFieldValues.textEditingController,
              focusNode: inputFieldValues.focusNode,
              keyboardAppearance: Brightness.dark,
              style: TextStyle(fontSize: 14, color: ColorName.white),
              decoration: InputDecoration(
                hintText: hasTags ? '' : 'Add tags (optional)',
                prefixIconConstraints: BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                  maxWidth: maxChipsWidth,
                ),
                prefixIcon: hasTags
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: SingleChildScrollView(
                          controller: inputFieldValues.tagScrollController,
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: inputFieldValues.tags
                                .map((DynamicTagData<ButtonData> tag) {
                              return _TagChip(
                                label: tag.tag,
                                onRemove: () {
                                  inputFieldValues.onTagRemoved(tag);
                                  widget.onTagsChanged(inputFieldValues.tags
                                      .map((e) => e.tag)
                                      .toList());
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      )
                    : const Icon(Icons.tag_rounded, size: 20),
                suffixIcon: !hasTags
                    ? null
                    : IconButton(
                        tooltip: 'Clear tags',
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _dynamicTagController.clearTags();
                          widget.onTagsChanged([]);
                        },
                      ),
              ),
              onChanged: (value) {
                final button = ButtonData(ColorName.secondaryBlue, '');
                final tagData = DynamicTagData(value, button);
                inputFieldValues.onTagChanged(tagData);
                widget.onTagsChanged(
                    inputFieldValues.tags.map((e) => e.tag).toList());
              },
              onSubmitted: (value) {
                final button = ButtonData(ColorName.secondaryBlue, '');
                final tagData = DynamicTagData(value, button);
                inputFieldValues.onTagSubmitted(tagData);
              },
            );
          },
        );
      },
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _TagChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
      decoration: BoxDecoration(
        color: ColorName.primaryBlue.withAlpha(36),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ColorName.primaryBlue.withAlpha(100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              '#$label',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ColorName.white,
              ),
            ),
          ),
          const SizedBox(width: 2),
          InkWell(
            customBorder: const CircleBorder(),
            onTap: onRemove,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: ColorName.greyText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DynamicMultilineTags extends StatefulWidget {
  const DynamicMultilineTags({Key? key}) : super(key: key);

  @override
  State<DynamicMultilineTags> createState() => _DynamicMultilineTagsState();
}

class _DynamicMultilineTagsState extends State<DynamicMultilineTags> {
  late double _distanceToField;
  late DynamicTagController<DynamicTagData<ButtonData>> _dynamicTagController;
  final random = Random();

  static final List<DynamicTagData<ButtonData>> _initialTags = [
    DynamicTagData<ButtonData>(
      'cat',
      const ButtonData(
        Color.fromARGB(255, 202, 198, 253),
        "😽",
      ),
    ),
    DynamicTagData(
      'penguin',
      const ButtonData(
        Color.fromARGB(255, 199, 244, 255),
        '🐧',
      ),
    ),
    DynamicTagData(
      'tiger',
      const ButtonData(
        Color.fromARGB(255, 252, 195, 250),
        '🐯',
      ),
    ),
    DynamicTagData<ButtonData>(
      'whale',
      const ButtonData(
        Color.fromARGB(255, 209, 248, 193),
        "🐋",
      ),
    ),
    DynamicTagData(
      'bear',
      const ButtonData(
        Color.fromARGB(255, 254, 237, 199),
        '🐻',
      ),
    ),
    DynamicTagData(
      'lion',
      const ButtonData(
        Color.fromARGB(255, 252, 196, 196),
        '🦁',
      ),
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _distanceToField = MediaQuery.of(context).size.width;
  }

  @override
  void dispose() {
    super.dispose();
    _dynamicTagController.dispose();
  }

  @override
  void initState() {
    super.initState();
    _dynamicTagController = DynamicTagController<DynamicTagData<ButtonData>>();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextFieldTags<DynamicTagData<ButtonData>>(
          textfieldTagsController: _dynamicTagController,
          initialTags: _initialTags,
          textSeparators: const [' ', ','],
          letterCase: LetterCase.normal,
          validator: (DynamicTagData<ButtonData> tag) {
            if (tag.tag == 'lion') {
              return 'Not envited per tiger request';
            } else if (_dynamicTagController.getTags!
                .any((element) => element.tag == tag.tag)) {
              return 'Already in the club';
            }
            return null;
          },
          inputFieldBuilder: (context, inputFieldValues) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: TextField(
                onTap: () {
                  _dynamicTagController.getFocusNode?.requestFocus();
                },
                controller: inputFieldValues.textEditingController,
                focusNode: inputFieldValues.focusNode,
                decoration: InputDecoration(
                  isDense: true,
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 74, 137, 92),
                      width: 3.0,
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 74, 137, 92),
                      width: 3.0,
                    ),
                  ),
                  helperText: 'Zootopia club...',
                  helperStyle: const TextStyle(
                    color: Color.fromARGB(255, 74, 137, 92),
                  ),
                  hintText: inputFieldValues.tags.isNotEmpty
                      ? ''
                      : "Register name...",
                  errorText: inputFieldValues.error,
                  prefixIconConstraints:
                      BoxConstraints(maxWidth: _distanceToField * 0.8),
                  prefixIcon: inputFieldValues.tags.isNotEmpty
                      ? SingleChildScrollView(
                          controller: inputFieldValues.tagScrollController,
                          scrollDirection: Axis.vertical,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 8,
                              bottom: 8,
                              left: 8,
                            ),
                            child: Wrap(
                                runSpacing: 4.0,
                                spacing: 4.0,
                                children: inputFieldValues.tags
                                    .map((DynamicTagData<ButtonData> tag) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(20.0),
                                      ),
                                      color: tag.data.buttonColor,
                                    ),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 5.0),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10.0, vertical: 5.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          child: Text(
                                            '${tag.data.emoji} ${tag.tag}',
                                            style: const TextStyle(
                                                color: Color.fromARGB(
                                                    255, 0, 0, 0)),
                                          ),
                                          onTap: () {
                                            // print("${tag.tag} selected");
                                          },
                                        ),
                                        const SizedBox(width: 4.0),
                                        InkWell(
                                          child: const Icon(
                                            Icons.cancel,
                                            size: 14.0,
                                            color: Color.fromARGB(255, 0, 0, 0),
                                          ),
                                          onTap: () {
                                            inputFieldValues.onTagRemoved(tag);
                                          },
                                        )
                                      ],
                                    ),
                                  );
                                }).toList()),
                          ),
                        )
                      : null,
                ),
                onChanged: (value) {
                  final getColor = Color.fromARGB(
                      random.nextInt(256),
                      random.nextInt(256),
                      random.nextInt(256),
                      random.nextInt(256));
                  final button = ButtonData(getColor, '✨');
                  final tagData = DynamicTagData(value, button);
                  inputFieldValues.onTagChanged(tagData);
                },
                onSubmitted: (value) {
                  final getColor = Color.fromARGB(
                      random.nextInt(256),
                      random.nextInt(256),
                      random.nextInt(256),
                      random.nextInt(256));
                  final button = ButtonData(getColor, '✨');
                  final tagData = DynamicTagData(value, button);
                  inputFieldValues.onTagSubmitted(tagData);
                },
              ),
            );
          },
        ),
        ElevatedButton(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all<Color>(
              const Color.fromARGB(255, 74, 137, 92),
            ),
          ),
          onPressed: () {
            _dynamicTagController.clearTags();
          },
          child: Text(
            'CLEAR TAGS',
            style: TextStyle(color: ColorName.white),
          ),
        ),
      ],
    );
  }
}

class DynamicAutoCompleteTags extends StatefulWidget {
  const DynamicAutoCompleteTags({Key? key}) : super(key: key);

  @override
  State<DynamicAutoCompleteTags> createState() =>
      _DynamicAutoCompleteTagsState();
}

class _DynamicAutoCompleteTagsState extends State<DynamicAutoCompleteTags> {
  late double _distanceToField;
  late DynamicTagController<DynamicTagData<ButtonData>> _dynamicTagController;
  final random = Random();

  static final List<DynamicTagData<ButtonData>> _initialTags = [
    DynamicTagData<ButtonData>(
      'cat',
      const ButtonData(
        Color.fromARGB(255, 202, 198, 253),
        "😽",
      ),
    ),
    DynamicTagData(
      'penguin',
      const ButtonData(
        Color.fromARGB(255, 199, 244, 255),
        '🐧',
      ),
    ),
    DynamicTagData(
      'tiger',
      const ButtonData(
        Color.fromARGB(255, 252, 195, 250),
        '🐯',
      ),
    ),
    DynamicTagData<ButtonData>(
      'whale',
      const ButtonData(
        Color.fromARGB(255, 209, 248, 193),
        "🐋",
      ),
    ),
    DynamicTagData<ButtonData>(
      'bear',
      const ButtonData(
        Color.fromARGB(255, 254, 237, 199),
        '🐻',
      ),
    ),
    DynamicTagData(
      'lion',
      const ButtonData(
        Color.fromARGB(255, 252, 196, 196),
        '🦁',
      ),
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _distanceToField = MediaQuery.of(context).size.width;
  }

  @override
  void dispose() {
    super.dispose();
    _dynamicTagController.dispose();
  }

  @override
  void initState() {
    super.initState();
    _dynamicTagController = DynamicTagController<DynamicTagData<ButtonData>>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 74, 137, 92),
        centerTitle: true,
        title: Text(
          'Dynamic Tag Autocomplete Demo',
          style: TextStyle(
            color: ColorName.white,
            fontSize: 18.0,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            Autocomplete<DynamicTagData<ButtonData>>(
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topCenter,
                  child: Material(
                    elevation: 4.0,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final DynamicTagData<ButtonData> option =
                              options.elementAt(index);
                          return TextButton(
                            onPressed: () {
                              onSelected(option);
                            },
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '#${option.data.emoji}${option.tag}',
                                textAlign: TextAlign.left,
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 74, 137, 92),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
              fieldViewBuilder: (context, textEditingController, focusNode,
                  onFieldSubmitted) {
                return TextFieldTags<DynamicTagData<ButtonData>>(
                  textfieldTagsController: _dynamicTagController,
                  textEditingController: textEditingController,
                  focusNode: focusNode,
                  textSeparators: const [' ', ','],
                  letterCase: LetterCase.normal,
                  validator: (DynamicTagData<ButtonData> tag) {
                    if (tag.tag == 'lion') {
                      return 'Not envited per tiger request';
                    } else if (_dynamicTagController.getTags!
                        .any((element) => element.tag == tag.tag)) {
                      return 'Already in the club';
                    }
                    return null;
                  },
                  inputFieldBuilder: (context, inputFieldValues) {
                    return Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: TextField(
                        controller: inputFieldValues.textEditingController,
                        focusNode: inputFieldValues.focusNode,
                        decoration: InputDecoration(
                          isDense: true,
                          border: const OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromARGB(255, 74, 137, 92),
                              width: 3.0,
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromARGB(255, 74, 137, 92),
                              width: 3.0,
                            ),
                          ),
                          helperText: 'Zootopia club...',
                          helperStyle: const TextStyle(
                            color: Color.fromARGB(255, 74, 137, 92),
                          ),
                          hintText: inputFieldValues.tags.isNotEmpty
                              ? ''
                              : "Register name...",
                          errorText: inputFieldValues.error,
                          prefixIconConstraints:
                              BoxConstraints(maxWidth: _distanceToField * 0.74),
                          prefixIcon: inputFieldValues.tags.isNotEmpty
                              ? SingleChildScrollView(
                                  controller:
                                      inputFieldValues.tagScrollController,
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                      children: inputFieldValues.tags.map(
                                          (DynamicTagData<ButtonData> tag) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.all(
                                          Radius.circular(20.0),
                                        ),
                                        color: tag.data.buttonColor,
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 5.0),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10.0, vertical: 5.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          InkWell(
                                            child: Text(
                                              '${tag.data.emoji} ${tag.tag}',
                                              style: const TextStyle(
                                                  color: Color.fromARGB(
                                                      255, 0, 0, 0)),
                                            ),
                                            onTap: () {
                                              // print("${tag.tag} selected");
                                            },
                                          ),
                                          const SizedBox(width: 4.0),
                                          InkWell(
                                            child: const Icon(
                                              Icons.cancel,
                                              size: 14.0,
                                              color:
                                                  Color.fromARGB(255, 0, 0, 0),
                                            ),
                                            onTap: () {
                                              inputFieldValues
                                                  .onTagRemoved(tag);
                                            },
                                          )
                                        ],
                                      ),
                                    );
                                  }).toList()),
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          final getColor = Color.fromARGB(
                              random.nextInt(256),
                              random.nextInt(256),
                              random.nextInt(256),
                              random.nextInt(256));
                          final button = ButtonData(getColor, '✨');
                          final tagData = DynamicTagData(value, button);
                          inputFieldValues.onTagChanged(tagData);
                        },
                        onSubmitted: (value) {
                          final getColor = Color.fromARGB(
                              random.nextInt(256),
                              random.nextInt(256),
                              random.nextInt(256),
                              random.nextInt(256));
                          final button = ButtonData(getColor, '✨');
                          final tagData = DynamicTagData(value, button);
                          inputFieldValues.onTagSubmitted(tagData);
                        },
                      ),
                    );
                  },
                );
              },
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') {
                  return const Iterable<DynamicTagData<ButtonData>>.empty();
                }
                return _initialTags.where((DynamicTagData<ButtonData> option) {
                  return option.tag
                      .contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (option) {
                _dynamicTagController.onTagSubmitted(option);
              },
            ),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all<Color>(
                  const Color.fromARGB(255, 74, 137, 92),
                ),
              ),
              onPressed: () {
                _dynamicTagController.clearTags();
              },
              child: Text(
                'CLEAR TAGS',
                style: TextStyle(color: ColorName.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
