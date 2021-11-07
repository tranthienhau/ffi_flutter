enum FormDataType { text, file }

///Form data use to post form data in curl
class FormData {
  FormData({
    required this.name,
    required this.type,
    required this.value,
  });

  final String name;
  final String value;
  final FormDataType type;
}
