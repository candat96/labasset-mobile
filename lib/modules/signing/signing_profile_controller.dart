import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/errors/api_error.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/models/signing.dart';
import '../../data/repositories/signing_repository.dart';

/// Cài đặt chữ ký số của tài khoản đang đăng nhập.
///
/// Không bao giờ giữ lại mật khẩu/PIN đã lưu: sau khi đọc hồ sơ chỉ điền tên
/// đăng nhập và trạng thái nhớ PIN, còn hai ô bí mật luôn để trống.
class SigningProfileController extends GetxController {
  SigningProfileController({required this.repo});

  final SigningRepository repo;

  final RxBool loading = true.obs;
  final RxBool saving = false.obs;
  final RxBool lookingUp = false.obs;
  final RxBool configured = false.obs;
  final Rxn<SigningProfile> profile = Rxn<SigningProfile>();
  final Rxn<SigningCertificate> selected = Rxn<SigningCertificate>();
  final RxList<SigningCertificate> certificates = <SigningCertificate>[].obs;
  final Rxn<Object> error = Rxn<Object>();

  final username = TextEditingController();
  final password = TextEditingController();
  final pin = TextEditingController();

  final RxBool rememberPin = false.obs;
  final RxBool hidePassword = true.obs;
  final RxBool hidePin = true.obs;

  final RxnString usernameError = RxnString();
  final RxnString passwordError = RxnString();
  final RxnString pinError = RxnString();
  final RxnString certError = RxnString();

  /// Chứng thư đang hiển thị: cái vừa chọn, hoặc chứng thư đã lưu trong hồ sơ.
  SigningCertificate? get _effectiveCertificate => selected.value;

  SigningProfile? get currentProfile => profile.value;

  DateTime? get _effectiveValidTo {
    final picked = _effectiveCertificate;
    if (picked != null) return DateTime.tryParse(picked.validTo);
    final p = profile.value;
    return p == null ? null : DateTime.tryParse(p.certValidTo);
  }

  bool get hasCertificate =>
      selected.value != null ||
      (profile.value?.credentialId.isNotEmpty ?? false);

  bool get expired {
    final to = _effectiveValidTo;
    return to != null && !to.isAfter(DateTime.now());
  }

  bool get expiringSoon {
    final to = _effectiveValidTo;
    if (to == null) return false;
    final left = to.difference(DateTime.now());
    return left > Duration.zero && left <= const Duration(days: 30);
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final res = await repo.profile();
      configured.value = res.configured;
      profile.value = res.profile;
      final p = res.profile;
      if (p != null) {
        username.text = p.username;
        rememberPin.value = p.rememberPin;
      }
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  /// Tra chứng thư theo tên đăng nhập; trả danh sách để view mở sheet chọn.
  Future<List<SigningCertificate>> lookup() async {
    final u = username.text.trim();
    if (u.isEmpty) {
      usernameError.value = 'signing.usernameRequired'.tr;
      return const [];
    }
    usernameError.value = null;
    certError.value = null;
    lookingUp.value = true;
    try {
      final list = await repo.certificates(u);
      certificates.assignAll(list);
      if (list.isEmpty) certError.value = 'signing.noCertificate'.tr;
      return list;
    } catch (e) {
      certError.value = ApiError.messageFor(e);
      AppSnackbar.error(e);
      return const [];
    } finally {
      lookingUp.value = false;
    }
  }

  void pickCertificate(SigningCertificate cert) {
    selected.value = cert;
    certError.value = null;
  }

  Future<bool> save() async {
    usernameError.value = null;
    passwordError.value = null;
    pinError.value = null;
    certError.value = null;

    final u = username.text.trim();
    if (u.isEmpty) {
      usernameError.value = 'signing.usernameRequired'.tr;
      return false;
    }
    final p = profile.value;
    final cert = selected.value;
    final credentialId = cert?.keyId ?? p?.credentialId;
    if (credentialId == null || credentialId.isEmpty) {
      certError.value = 'signing.noCertSelected'.tr;
      return false;
    }
    // Chưa có mật khẩu lưu sẵn thì bắt buộc nhập để provider đăng nhập được.
    if ((p == null || !p.passwordSet) && password.text.isEmpty) {
      passwordError.value = 'signing.passwordRequired'.tr;
      return false;
    }
    // Bật nhớ PIN mà chưa có PIN lưu sẵn thì phải nhập, nếu không server xoá PIN.
    if (rememberPin.value && pin.text.isEmpty && (p == null || !p.pinSet)) {
      pinError.value = 'signing.pinRequired'.tr;
      return false;
    }

    saving.value = true;
    try {
      final saved = await repo.save(
        username: u,
        rememberPin: rememberPin.value,
        credentialId: credentialId,
        certSerial: cert?.serial ?? p!.certSerial,
        certSubject: cert?.subject ?? p!.certSubject,
        certValidFrom: cert?.validFrom ?? p!.certValidFrom,
        certValidTo: cert?.validTo ?? p!.certValidTo,
        password: password.text,
        pin: pin.text,
      );
      profile.value = saved;
      selected.value = null;
      certificates.clear();
      password.clear();
      pin.clear();
      AppSnackbar.success('signing.saved'.tr);
      return true;
    } catch (e) {
      AppSnackbar.error(e);
      return false;
    } finally {
      saving.value = false;
    }
  }

  Future<void> clearSession() async {
    try {
      await repo.clearSession();
      await load();
      AppSnackbar.success('signing.clearSessionDone'.tr);
    } catch (e) {
      AppSnackbar.error(e);
    }
  }

  @override
  void onClose() {
    username.dispose();
    password.dispose();
    pin.dispose();
    super.onClose();
  }
}
