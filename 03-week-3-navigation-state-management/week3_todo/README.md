# Praktikum 3
1. Ubah build() sementara untuk melempar error: throw Exception('Gagal terhubung ke server');. Jalankan dan amati UI error beserta tombol Coba lagi.

2. Refleksikan: mengapa menampilkan ulang data lama (stale data) dengan indikator refresh kadang lebih baik daripada mengosongkan layar? Kapan pola itu penting?
Menampilkan data lama dan indikator refresh lebih baik daripada mengosongkan layar karena user tetap bisa melihat dan berinteraksi dengan konten yang ada, jika layar dikosongkan akan memberikan kesan aplikasi "rusak". Menurut saya pola ini penting di infinite scroll / pagination (situasi data lama masih relevan saat menunggu data baru)