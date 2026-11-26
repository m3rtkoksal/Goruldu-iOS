/// Words left out of the "Sözlük" card. Mirrors `karne/stopwords.txt` in the API repository;
/// `StopwordsTests` fails when the two drift apart.
enum Stopwords {
    static let all: Set<String> = [
        "ve", "bir", "bu", "şu", "ben", "sen", "biz", "siz",
        "onlar", "ama", "için", "ile", "gibi", "çok", "daha", "var",
        "yok", "değil", "evet", "hayır", "neden", "nasıl", "kim", "şey",
        "yani", "bence", "bana", "sana", "beni", "seni", "bizi", "ona",
        "onu", "bunu", "şunu", "kadar", "sonra", "önce", "şimdi", "bugün",
        "yarın", "dün", "olur", "oldu", "olsun", "olan", "olarak", "zaten",
        "hiç", "her", "hep", "bile", "artık", "aslında", "falan", "filan",
        "tam", "diye", "dedi", "dedim", "bende", "sende", "orada", "burada",
        "böyle", "öyle", "şöyle", "biraz", "bazı", "tüm", "hem", "veya",
        "ise", "the", "and", "you", "that", "for", "are", "but",
        "not", "with", "have", "this", "was", "what", "your", "just",
        "can", "all", "get", "out", "its", "from", "they", "will",
        "would", "there", "their", "about", "when", "been", "were", "has",
        "had", "him", "her", "she", "his", "how", "who", "why",
        "too", "now", "then", "than", "them", "don", "dont", "didn",
        "doesn", "won", "isn", "did", "got", "one", "our",
    ]
}
