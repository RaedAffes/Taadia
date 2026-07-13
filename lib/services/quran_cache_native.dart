class QuranCache {
  Future<void> init() async {}
  Future<String?> getPage(int page) async => null;
  Future<void> savePage(int page, String svg) async {}
  Future<Set<int>> getCompletedPages() async => {};
  Future<void> saveCompletedPages(Set<int> pages) async {}
}
