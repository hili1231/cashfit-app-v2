class ProgressVideo {
  final String url;
  final DateTime uploadedAt;

  ProgressVideo({required this.url, required this.uploadedAt});

  Map<String, dynamic> toMap() => {
    'url': url,
    'uploadedAt': uploadedAt.toIso8601String(),
  };

  factory ProgressVideo.fromMap(Map<String, dynamic> map) {
    return ProgressVideo(
      url: map['url'] ?? '',
      uploadedAt: DateTime.tryParse(map['uploadedAt'] ?? '') ?? DateTime.now(),
    );
  }
}
