class ValidationUtils {
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return "يرجى إدخال $fieldName";
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "يرجى إدخال البريد الإلكتروني";
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return "يرجى إدخال بريد إلكتروني صحيح";
    }

    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "يرجى إدخال رقم الهاتف";
    }

    final phoneRegex = RegExp(r'^[\+]?[0-9]{8,15}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return "يرجى إدخال رقم هاتف صحيح";
    }

    return null;
  }

  static String? validateEmailOrPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "يرجى إدخال البريد الإلكتروني أو رقم الهاتف";
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    final phoneRegex = RegExp(r'^[\+]?[0-9]{8,15}$');

    if (!emailRegex.hasMatch(value.trim()) &&
        !phoneRegex.hasMatch(value.trim())) {
      return "يرجى إدخال بريد إلكتروني أو رقم هاتف صحيح";
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "يرجى إدخال كلمة المرور";
    }
    if (value.length < 6) {
      return "كلمة المرور يجب أن تكون 6 أحرف على الأقل";
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return "يرجى تأكيد كلمة المرور";
    }
    if (value != password) {
      return "كلمة المرور غير متطابقة";
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "يرجى إدخال الاسم";
    }
    if (value.trim().length < 2) {
      return "الاسم يجب أن يكون حرفين على الأقل";
    }
    return null;
  }
}
