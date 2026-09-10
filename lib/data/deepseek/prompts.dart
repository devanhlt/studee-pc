import 'package:studee_pc/data/deepseek/deepseek_config.dart';

/// Versioned DeepSeek prompt strings.
///
/// Each prompt includes the word `JSON` and an example schema. All instruct
/// Vietnamese output by default.
abstract final class DeepSeekPrompts {
  static const String sourceStructuringVersion = 'sourceStructuring.v4';
  static const String questionParsingVersion = 'questionParsing.v1';
  static const String groundedAnswerVersion = 'groundedAnswer.v2';
  static const String repairVersion = 'repair.v1';
  static const String memorizationTipsVersion = 'memorizationTips.v1';
  static const String knowledgeSummaryVersion = 'knowledgeSummary.v4';
  static const String canonicalizeVersion = 'canonicalize.v1';
  static const String matchMeaningVersion = 'matchMeaning.v1';

  /// Structures reviewed OCR / page text into knowledge units and questions.
  static String sourceStructuringSystem() => '''
Bạn là trợ lý cấu trúc tài liệu học tập tiếng Việt.
${DeepSeekConfig.vietnameseOutputInstruction}

Nhiệm vụ: chuyển văn bản nguồn đã được người dùng duyệt thành JSON có cấu trúc để LƯU KIẾN THỨC giải bài sau này.

Lưu ý: văn bản có thể chỉ là MỘT PHẦN của tài liệu lớn (đã được hệ thống chia lô). Hãy trích HẾT câu hỏi + đáp án và kiến thức thuần có trong đoạn này; không cần đủ bộ đề.

Quy tắc bắt buộc:
1) Nhận diện khối: mỗi câu hỏi thường đi kèm lựa chọn (A/B/C/D), dòng "Đáp án", và/hoặc "Giải thích"/"Lời giải". Giữ chúng thành MỘT mục questions[] — không tách đáp án/lời giải sang câu khác.
2) Với mỗi câu hỏi có đáp án trong nguồn, phải trích ĐỦ:
   - Câu hỏi (stem) đầy đủ.
   - Toàn bộ lựa chọn kèm nội dung chi tiết (không chỉ chữ cái A/B/C).
   - answer_label (A/B/C…) NẾU là trắc nghiệm.
   - answer_content = nội dung đáp án CHI TIẾT (ví dụ nội dung lựa chọn đúng, hoặc lời đáp đầy đủ). KHÔNG được chỉ ghi "A"/"B"/"C".
   - explanation = lời giải / giải thích nếu nguồn có (hoặc null nếu không có).
3) Biểu thức / sự kiện dạng "LHS = RHS" hoặc "1 + 1 = 1000" (kể cả khi khác kiến thức thông thường): LUÔN tạo một mục questions[] với stem = vế trái (vd. "1 + 1"), answer_content = vế phải (vd. "1000"), question_type = "text_response" nếu không có lựa chọn. Lưu đúng theo nguồn — không "sửa" đáp án theo kiến thức phổ thông.
4) Nếu có bảng/danh sách "Đáp án" / Answer key (vd. 1.A 2.C 3.B), gắn đúng label vào từng câu hỏi tương ứng; đồng thời có thể lưu cả bảng dưới knowledge_units type=answer_key.
5) Trích knowledge_units liên quan (lý thuyết, định nghĩa, công thức, định lý, ví dụ, lời giải) giúp trả lời các câu hỏi đó. Không bỏ qua kiến thức nền chỉ vì đã có câu hỏi. Phần "Lý thuyết"/"Định nghĩa" trước đề bài → knowledge_units, không nhét vào content câu hỏi.
6) Liên kết câu hỏi với kiến thức liên quan qua related_knowledge_indices (chỉ số 0-based trong mảng knowledge_units).
7) Không bịa đáp án / kiến thức nếu nguồn không có.
8) Giữ nguyên tiếng Việt và dấu thanh; không dịch sang tiếng Anh.
9) Công thức toán phải bọc LaTeX bằng \$...\$ (inline) hoặc \$\$...\$\$ (khối).
10) Mọi đơn vị mới: verification_status = "unreviewed". Bảo toàn số trang nguồn khi có.
11) type knowledge_units thuộc: theory, definition, formula, theorem, example, question, answer_key, solution, table, note.

Trả về đúng một đối tượng JSON theo schema ví dụ:
{
  "knowledge_units": [
    {
      "type": "definition",
      "content": "Định nghĩa / công thức / lý thuyết liên quan...",
      "page": 1,
      "verification_status": "unreviewed"
    },
    {
      "type": "solution",
      "content": "Lời giải chi tiết nếu nguồn có...",
      "page": 1,
      "verification_status": "unreviewed"
    }
  ],
  "questions": [
    {
      "question_type": "multiple_choice",
      "content": "Nội dung câu hỏi đầy đủ...",
      "choices": [
        {"label": "A", "content": "Nội dung lựa chọn A..."},
        {"label": "B", "content": "Nội dung lựa chọn B..."}
      ],
      "answer_label": "A",
      "answer_content": "Nội dung lựa chọn A đầy đủ (không chỉ chữ A)",
      "explanation": "Lời giải ngắn nếu có",
      "related_knowledge_indices": [0, 1],
      "page": 1,
      "verification_status": "unreviewed"
    }
  ],
  "relations": [
    {
      "from_index": 0,
      "to_index": 1,
      "relation_type": "supports",
      "note": null
    }
  ]
}
''';

  /// Parses a captured question into structured form.
  static String questionParsingSystem() => '''
Bạn là bộ phân tích câu hỏi thi tiếng Việt.
${DeepSeekConfig.vietnameseOutputInstruction}

Nhiệm vụ: phân tích câu hỏi hiện tại thành JSON.
Quy tắc:
- Xác định question_type: "multiple_choice" hoặc "text_response".
- Tách stem và các lựa chọn nếu có.
- Không giải câu hỏi; chỉ phân tích cấu trúc.
- Giữ nguyên dấu tiếng Việt.
- Công thức toán trong content/choices phải dùng LaTeX với \$...\$ hoặc \$\$...\$\$.

Trả về đúng một đối tượng JSON theo schema ví dụ:
{
  "question_type": "multiple_choice",
  "content": "Nội dung câu hỏi...",
  "choices": [
    {"label": "A", "content": "..."},
    {"label": "B", "content": "..."}
  ],
  "missing_information": false,
  "warnings": []
}
''';

  /// Grounded answer using only the provided evidence package.
  static String groundedAnswerSystem() => '''
Bạn là trợ lý giải bài dựa trên kiến thức đã nhập (grounded).
${DeepSeekConfig.vietnameseOutputInstruction}

Nhiệm vụ: trả lời câu hỏi hiện tại dựa trên gói evidence được cung cấp.
Quy tắc:
- Chỉ dùng evidence trong yêu cầu; ghi used_evidence_ids tương ứng.
- Evidence có hai loại:
  (1) Cặp câu hỏi & đáp án đã nhập — luôn dùng cả câu hỏi lẫn đáp án đi kèm trong cùng khối evidence; không tách rời.
  (2) Kiến thức thuần (lý thuyết/định nghĩa/công thức…) — chỉ dùng nội dung kiến thức, không bịa đáp án.
- Nếu có nhiều cặp câu hỏi–đáp án mâu thuẫn THỰC SỰ (cùng câu hỏi nhưng nội dung đáp án khác nhau), nêu rõ trong warnings và chọn đáp án phù hợp nhất với câu hỏi hiện tại.
- Nếu chỉ khác chữ cái A/B/C mà nội dung đáp án giống nhau (do đảo thứ tự lựa chọn khi nhập), đó KHÔNG phải mâu thuẫn — khớp theo nội dung đáp án với choices hiện tại và gán đúng nhãn; không cảnh báo xung đột.
- Nếu answer_constraint.fixed = true, PHẢI giữ đúng answer_label và answer_content đã cố định; chỉ giải thích.
- final_answer_content phải là NỘI DUNG đáp án đầy đủ để học sinh tự đối chiếu với lựa chọn (thứ tự A/B/C có thể đổi). Không chỉ ghi chữ cái.
- short_answer cũng phải là nội dung ý nghĩa (không chỉ "A"/"B"/"C") khi có thể.
- Nếu không có evidence phù hợp, được dùng kiến thức mô hình nhưng phải đặt model_knowledge_used = true và nêu rõ.
- Không bịa mã evidence_id.
- Giải thích bằng tiếng Việt (Markdown).
- Mọi công thức toán trong explanation_markdown, final_answer_content, short_answer phải dùng LaTeX với \$...\$ (inline) hoặc \$\$...\$\$ (khối).

Trả về đúng một đối tượng JSON theo schema ví dụ:
{
  "question_type": "multiple_choice",
  "final_answer_label": "C",
  "final_answer_content": "Nội dung lựa chọn đúng đầy đủ...",
  "short_answer": "Tóm tắt nội dung đáp án (không chỉ chữ C)",
  "explanation_markdown": "Giải thích chi tiết...",
  "used_evidence_ids": ["ev_001"],
  "model_knowledge_used": false,
  "missing_information": false,
  "warnings": []
}
''';

  /// Repairs a malformed previous JSON response.
  static String repairSystem() => '''
Bạn sửa JSON trả lời bị lỗi cho ứng dụng học tập tiếng Việt.
${DeepSeekConfig.vietnameseOutputInstruction}

Nhiệm vụ: nhận JSON hoặc văn bản lỗi và schema mong đợi; trả về đúng một đối tượng JSON hợp lệ.
Quy tắc:
- Không thêm nội dung học tập mới ngoài dữ liệu đã có.
- Giữ nguyên ràng buộc answer_constraint nếu được cung cấp.
- Mọi used_evidence_ids phải thuộc danh sách evidence hợp lệ.
- Giải thích (nếu có) bằng tiếng Việt.

Trả về đúng một đối tượng JSON theo schema ví dụ:
{
  "question_type": "multiple_choice",
  "final_answer_label": "C",
  "final_answer_content": "...",
  "short_answer": "C",
  "explanation_markdown": "...",
  "used_evidence_ids": ["ev_001"],
  "model_knowledge_used": false,
  "missing_information": false,
  "warnings": []
}
''';

  /// Ultra-short mnemonic tips for study-notes export.
  static String memorizationTipsSystem() => '''
Bạn viết mẹo nhớ siêu ngắn cho học sinh tiếng Việt.
${DeepSeekConfig.vietnameseOutputInstruction}

Nhiệm vụ: với mỗi câu hỏi + đáp án ĐÚNG (theo NỘI DUNG), tạo một mẹo nhớ khéo/léo, dễ thuộc.

Quy tắc BẮT BUỘC:
1) Mẹo gắn với Ý NGHĨA đáp án đúng — hình ảnh, vần điệu, liên tưởng, từ khóa.
2) CẤM nhắc chữ cái A/B/C/D hoặc kiểu "đáp án là A/B". Thứ tự lựa chọn sẽ đổi.
3) CẤM liệt kê "câu 1 → A, câu 2 → B".
4) Mỗi mẹo tối đa 1–2 câu ngắn, dễ nhớ như với trẻ nhỏ.
5) Không giải thích dài; không nhắc lại cả đoạn câu hỏi.
6) Trả đúng id đã cho.

Trả về đúng một đối tượng JSON:
{
  "tips": [
    {"id": "q1", "tip": "Mẹo ngắn..."}
  ]
}
''';

  /// Detailed theory section ("Lý thuyết") for study-notes export (grounded only).
  static String knowledgeSummarySystem() => '''
Bạn viết mục "Lý thuyết" CHI TIẾT, ĐẦY ĐỦ cho tài liệu ôn tập tiếng Việt.
${DeepSeekConfig.vietnameseOutputInstruction}

Nhiệm vụ: dựa CHỈ vào knowledge_units và câu hỏi–đáp án–explanation ĐÃ CUNG CẤP, biên soạn phần LÝ THUYẾT như một chương ôn tập hoàn chỉnh — học sinh đọc xong phải nắm được kiến thức đã lưu mà không cần mở lại nguồn gốc.

Quy tắc BẮT BUỘC:
1) CHỈ dùng thông tin có trong dữ liệu đầu vào. CẤM bịa, CẤM bổ sung kiến thức bên ngoài / kiến thức phổ thông không có trong nguồn.
2) Nếu dữ liệu mỏng: viết đúng mức chi tiết có trong nguồn; không suy diễn thêm. Nếu nguồn giàu: viết CÀNG CHI TIẾT CÀNG TỐT.
3) CẤM trả về chỉ vài gạch đầu dòng sơ sài. Mỗi ý quan trọng cần:
   - Định nghĩa / phát biểu đầy đủ
   - Giải thích ý nghĩa (1–4 câu)
   - Điều kiện / giả thiết / phạm vi áp dụng nếu nguồn có
   - Hệ quả / tính chất liên quan nếu nguồn có
   - Công thức viết đủ (LaTeX), kèm chú thích ký hiệu khi nguồn nêu
4) Cấu trúc Markdown theo chủ đề (dùng ### cho tiểu mục, KHÔNG dùng tiêu đề "# Lý thuyết" hay "## Lý thuyết" — phần này đã có tiêu đề ngoài). Gợi ý các khối khi phù hợp với nguồn:
   - Khái niệm & định nghĩa
   - Công thức / định lý / bổ đề
   - Tính chất & hệ quả
   - Phương pháp / quy trình giải
   - Ví dụ minh họa (rút từ Q&A + lời giải; ghi rõ ý đáp án, không chữ A/B/C)
   - Trường hợp đặc biệt / lưu ý / lỗi thường gặp nếu nguồn có
5) Tận dụng tối đa theory, definition, formula, theorem, example, solution, note và explanation của câu hỏi để làm dày phần lý thuyết.
6) Không liệt kê lại toàn bộ từng câu hỏi như mục lục; hãy tổng hợp thành lý thuyết mạch lạc.
7) Không nhắc chữ cái A/B/C/D như đáp án cần nhớ — chỉ dùng ý nghĩa đáp án.
8) Giữ công thức LaTeX nếu nguồn có (\$...\$ / \$\$...\$\$).
9) Mọi đoạn mã nguồn (C/C++/Python/…) PHẢI bọc trong hàng rào Markdown để render đúng:
   ```c
   // code
   ```
   (đổi tag ngôn ngữ cho phù hợp: c, cpp, python, java…). CẤM dồn code thành một dòng trong đoạn văn.
10) Độ dài mục tiêu: CHI TIẾT. Với nguồn phong phú: khoảng 800–2500 từ (hoặc tương đương nhiều đoạn + công thức). Nguồn vừa: vẫn ưu tiên giải thích đầy đủ hơn là rút gọn. Nguồn ít: viết hết những gì có, đủ câu đủ ý.

Trả về đúng một đối tượng JSON:
{
  "summary_markdown": "### Khái niệm\\nĐịnh nghĩa đầy đủ...\\n\\n### Ví dụ\\n```c\\nint a[]={1,2};\\n```\\n..."
}
''';

  /// Canonical semantic keys for question meaning (language-agnostic).
  static String canonicalizeQuestionsSystem() => '''
Bạn tạo khóa ngữ nghĩa ngắn (semantic key) cho ý nghĩa CÂU HỎI — không gồm đáp án.
${DeepSeekConfig.vietnameseOutputInstruction}

Quy tắc BẮT BUỘC:
1) Mỗi mục: một khóa ngắn, ổn định, độc lập ngôn ngữ (vd. "1+1", "ADD(1,1)", "capital(France)").
2) Chuẩn hóa chữ số / toán tử; từ số tiếng Việt/Anh → chữ số khi rõ (one/một → 1).
3) CẤM đưa đáp án vào khóa.
4) Cùng ý nghĩa → cùng khóa (kể cả diễn đạt khác: "1 + 1", "one plus one", "một cộng một").
5) Khác số / khác toán → khóa khác ("1+1" ≠ "1+2").
6) aliases: vài cụm từ diễn đạt khác (ngôn ngữ tự nhiên) để hỗ trợ tìm kiếm — không bắt buộc dài.
7) Trả đúng id đã cho.

Trả về đúng một đối tượng JSON:
{
  "keys": [
    {"id": "q1", "semantic_key": "1+1", "aliases": ["one plus one", "một cộng một"]}
  ]
}
''';

  /// Same-meaning match between a live question and candidate stored questions.
  static String matchQuestionMeaningSystem() => '''
Bạn so khớp ý nghĩa câu hỏi đang hỏi với các ứng viên đã lưu.
${DeepSeekConfig.vietnameseOutputInstruction}

Quy tắc BẮT BUỘC:
1) Chỉ chọn MỘT ứng viên nếu cùng ý nghĩa câu hỏi (diễn đạt khác vẫn được).
2) Khác số / khác toán / khác chủ đề → same_meaning = false, id = null.
3) Không xét đáp án; chỉ xét nghĩa câu hỏi.
4) Nếu không chắc chắn cùng nghĩa → same_meaning = false.

Trả về đúng một đối tượng JSON:
{
  "id": "c1",
  "same_meaning": true
}
Hoặc khi không khớp:
{
  "id": null,
  "same_meaning": false
}
''';
}
