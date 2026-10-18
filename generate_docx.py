import os
import docx
from docx import Document
from docx.shared import Inches, Pt, RGBColor, Cm
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

def set_cell_background(cell, fill_hex):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill_hex}"/>')
    tcPr.append(shd)

def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = parse_xml(f'<w:tcMar {nsdecls("w")}><w:top w:w="{top}" w:type="dxa"/><w:bottom w:w="{bottom}" w:type="dxa"/><w:left w:w="{left}" w:type="dxa"/><w:right w:w="{right}" w:type="dxa"/></w:tcMar>')
    tcPr.append(tcMar)

def set_table_borders(table, color="CBD5E1", sz="4", val="single"):
    tblPr = table._tbl.tblPr
    borders = parse_xml(
        f'<w:tblBorders {nsdecls("w")}>'
        f'<w:top w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>'
        f'<w:left w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>'
        f'<w:bottom w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>'
        f'<w:right w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>'
        f'<w:insideH w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>'
        f'<w:insideV w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>'
        f'</w:tblBorders>'
    )
    tblPr.append(borders)

def add_callout(doc, text_lines, bg_hex="F0FDF4", border_hex="16A34A", prefix=""):
    table = doc.add_table(rows=1, cols=1)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False
    
    cell = table.cell(0, 0)
    cell.width = Cm(17.4)
    set_cell_background(cell, bg_hex)
    set_cell_margins(cell, top=140, bottom=140, left=200, right=200)
    
    tcPr = cell._tc.get_or_add_tcPr()
    borders = parse_xml(
        f'<w:tcBorders {nsdecls("w")}>'
        f'<w:left w:val="single" w:sz="24" w:space="0" w:color="{border_hex}"/>'
        f'<w:top w:val="none"/>'
        f'<w:bottom w:val="none"/>'
        f'<w:right w:val="none"/>'
        f'</w:tcBorders>'
    )
    tcPr.append(borders)
    
    p = cell.paragraphs[0]
    p.paragraph_format.space_before = Pt(2)
    p.paragraph_format.space_after = Pt(2)
    p.paragraph_format.line_spacing = 1.15
    
    for i, line in enumerate(text_lines):
        if i > 0:
            p = cell.add_paragraph()
            p.paragraph_format.space_before = Pt(2)
            p.paragraph_format.space_after = Pt(2)
            p.paragraph_format.line_spacing = 1.15
        
        # Parse simple bold markdown **bold**
        parts = line.split("**")
        for j, part in enumerate(parts):
            run = p.add_run(part)
            run.font.name = "Calibri"
            run.font.size = Pt(11)
            if j % 2 == 1:
                run.bold = True
                run.font.color.rgb = RGBColor(15, 23, 42)
            else:
                run.font.color.rgb = RGBColor(51, 65, 85)
    
    p_spacer = doc.add_paragraph()
    p_spacer.paragraph_format.space_before = Pt(0)
    p_spacer.paragraph_format.space_after = Pt(4)

def add_code_block(doc, code_str):
    table = doc.add_table(rows=1, cols=1)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False
    
    cell = table.cell(0, 0)
    cell.width = Cm(17.4)
    set_cell_background(cell, "F8FAFC")
    set_cell_margins(cell, top=140, bottom=140, left=200, right=200)
    
    tcPr = cell._tc.get_or_add_tcPr()
    borders = parse_xml(
        f'<w:tcBorders {nsdecls("w")}>'
        f'<w:left w:val="single" w:sz="20" w:space="0" w:color="0284C7"/>'
        f'<w:top w:val="single" w:sz="4" w:space="0" w:color="E2E8F0"/>'
        f'<w:bottom w:val="single" w:sz="4" w:space="0" w:color="E2E8F0"/>'
        f'<w:right w:val="single" w:sz="4" w:space="0" w:color="E2E8F0"/>'
        f'</w:tcBorders>'
    )
    tcPr.append(borders)
    
    lines = code_str.strip().split("\n")
    p = cell.paragraphs[0]
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(0)
    p.paragraph_format.line_spacing = 1.1
    
    for i, line in enumerate(lines):
        if i > 0:
            p = cell.add_paragraph()
            p.paragraph_format.space_before = Pt(0)
            p.paragraph_format.space_after = Pt(0)
            p.paragraph_format.line_spacing = 1.1
        run = p.add_run(line)
        run.font.name = "Consolas"
        run.font.size = Pt(9.5)
        run.font.color.rgb = RGBColor(15, 23, 42)
    
    p_spacer = doc.add_paragraph()
    p_spacer.paragraph_format.space_before = Pt(0)
    p_spacer.paragraph_format.space_after = Pt(4)

def generate_doc(output_path):
    doc = Document()
    
    # Page Setup - A4, margins 1.8cm
    for section in doc.sections:
        section.page_width = Cm(21.0)
        section.page_height = Cm(29.7)
        section.top_margin = Cm(1.8)
        section.bottom_margin = Cm(1.8)
        section.left_margin = Cm(1.8)
        section.right_margin = Cm(1.8)
    
    # Title
    p_title = doc.add_paragraph()
    p_title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_title.paragraph_format.space_before = Pt(0)
    p_title.paragraph_format.space_after = Pt(4)
    run_title = p_title.add_run("TÀI LIỆU ÔN TẬP & TRA CỨU MÃ NGUỒN ĐỒ ÁN")
    run_title.font.name = "Segoe UI"
    run_title.font.size = Pt(18)
    run_title.bold = True
    run_title.font.color.rgb = RGBColor(15, 23, 42)
    
    # Subtitle
    p_sub = doc.add_paragraph()
    p_sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_sub.paragraph_format.space_before = Pt(0)
    p_sub.paragraph_format.space_after = Pt(4)
    r1 = p_sub.add_run("CHỦ ĐỀ 02: LẬP TRÌNH BẤT ĐỒNG BỘ VỚI FUTURE & STREAM: XÂY DỰNG MODULE REACTIVE THỜI GIAN THỰC\n")
    r1.font.name = "Calibri"
    r1.font.size = Pt(11)
    r1.bold = True
    r1.font.color.rgb = RGBColor(2, 132, 199)
    
    r2 = p_sub.add_run("Ứng dụng: CryptoPulse Reactive Tracker   |   Nhóm sinh viên: Trần Văn Hợp & Mai Tuấn An")
    r2.font.name = "Calibri"
    r2.font.size = Pt(11)
    r2.font.color.rgb = RGBColor(71, 85, 105)
    r2.italic = True

    # Divider line
    p_div = doc.add_paragraph()
    p_div.paragraph_format.space_before = Pt(2)
    p_div.paragraph_format.space_after = Pt(12)
    r_div = p_div.add_run("―" * 48)
    r_div.font.color.rgb = RGBColor(203, 213, 225)
    p_div.alignment = WD_ALIGN_PARAGRAPH.CENTER

    # SECTION 1
    p_h1 = doc.add_paragraph()
    p_h1.paragraph_format.space_before = Pt(8)
    p_h1.paragraph_format.space_after = Pt(4)
    r_h1 = p_h1.add_run("PHẦN 1: BẢNG TRA CỨU NHANH VỊ TRÍ CODE TRONG ĐỒ ÁN")
    r_h1.font.name = "Segoe UI"
    r_h1.font.size = Pt(14)
    r_h1.bold = True
    r_h1.font.color.rgb = RGBColor(2, 132, 199)

    p_intro = doc.add_paragraph()
    p_intro.paragraph_format.space_before = Pt(0)
    p_intro.paragraph_format.space_after = Pt(8)
    r_intro = p_intro.add_run("Khi Thầy/Cô yêu cầu: ")
    r_intro.font.name = "Calibri"
    r_intro.font.size = Pt(11)
    r_intro_quote = p_intro.add_run('“Em hãy mở code và chỉ ra nội dung này nằm ở đâu trong đồ án?”')
    r_intro_quote.italic = True
    r_intro_quote.bold = True
    r_intro_quote.font.color.rgb = RGBColor(15, 23, 42)
    r_intro_quote.font.size = Pt(11)
    r_intro_end = p_intro.add_run(", bạn chỉ cần tra bảng và mở đúng file - dòng dưới đây:")
    r_intro_end.font.size = Pt(11)

    # TABLE (5 columns)
    # Total printable width: 17.4 cm
    # Col widths: 1.0, 3.8, 5.0, 3.4, 4.2 cm -> Total = 17.4 cm
    col_widths = [Cm(1.0), Cm(3.8), Cm(5.0), Cm(3.4), Cm(4.2)]
    table_data = [
        [
            "STT", "Nội dung kỹ thuật yêu cầu", "File chứa mã nguồn", "Vị trí dòng code", "Màn hình trên App"
        ],
        [
            "1",
            "Event Loop & Microtask Queue",
            "• lib/main.dart\n• lib/services/event_loop_simulator_service.dart\n• test/event_loop_order_test.dart",
            "• main.dart: Dòng 22 - 24\n• simulator_service: Dòng 47 - 132",
            "Tab 3: Phòng Thí Nghiệm Event Loop (event_loop_lab_screen.dart)"
        ],
        [
            "2",
            "Future & async / await",
            "• lib/services/crypto_price_stream_service.dart\n• lib/services/event_loop_simulator_service.dart",
            "• price_stream: Dòng 263, 369, 378\n• simulator: Dòng 65, 76, 129",
            "Nút bấm BINANCE LIVE trên thanh tiêu đề (AppBar)"
        ],
        [
            "3",
            "Cơ chế Stream & StreamController",
            "• lib/services/crypto_price_stream_service.dart\n• lib/services/order_book_stream_service.dart\n• lib/views/crypto_market_screen.dart",
            "• price_stream: Dòng 35, 41, 68 - 80\n• order_book: Dòng 9, 17, 71\n• market_screen: Dòng 24, 38",
            "Huy hiệu Broadcasting / Active Listeners trên Header"
        ],
        [
            "4",
            "Broadcast Stream (Phát đa hướng)",
            "• Khởi tạo: lib/services/crypto_price_stream_service.dart\n• Nghe ở Trang chủ: lib/views/crypto_market_screen.dart\n• Nghe ở Chi tiết: lib/views/crypto_detail_screen.dart",
            "• Khởi tạo: Dòng 68\n• Trang chủ: Dòng 176\n• Chi tiết: Dòng 83",
            "Danh sách thị trường & Màn hình Chi tiết Coin cùng nhảy giá đồng thời"
        ],
        [
            "5",
            "Các toán tử biến đổi dữ liệu (Debounce, Throttle, Where)",
            "• lib/core/transformers/stream_transformers.dart\n• lib/views/crypto_market_screen.dart\n• lib/views/crypto_detail_screen.dart\n• lib/services/crypto_price_stream_service.dart",
            "• Định nghĩa: Toàn bộ file\n• Debounce 400ms: Dòng 38 - 47\n• Throttle 300ms: Dòng 85\n• Where: Dòng 253 - 255",
            "• Ô tìm kiếm Coin (Debounce 400ms)\n• Tab 2: Phòng Thí Nghiệm Toán Tử (stream_operators_lab_screen.dart)"
        ]
    ]

    table = doc.add_table(rows=len(table_data), cols=5)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False
    set_table_borders(table, color="CBD5E1", sz="4", val="single")

    for row_idx, row_content in enumerate(table_data):
        row = table.rows[row_idx]
        trPr = row._tr.get_or_add_trPr()
        trPr.append(parse_xml(f'<w:cantSplit {nsdecls("w")}/>'))
        if row_idx == 0:
            trPr.append(parse_xml(f'<w:tblHeader {nsdecls("w")}/>'))

        for col_idx, text in enumerate(row_content):
            cell = row.cells[col_idx]
            cell.width = col_widths[col_idx]
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER

            if row_idx == 0:
                set_cell_background(cell, "0284C7")
                set_cell_margins(cell, top=100, bottom=100, left=100, right=100)
            else:
                bg = "F8FAFC" if row_idx % 2 == 1 else "FFFFFF"
                set_cell_background(cell, bg)
                set_cell_margins(cell, top=80, bottom=80, left=90, right=90)

            p = cell.paragraphs[0]
            p.paragraph_format.space_before = Pt(0)
            p.paragraph_format.space_after = Pt(0)
            p.paragraph_format.line_spacing = 1.15

            if col_idx == 0 and row_idx > 0:
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            else:
                p.alignment = WD_ALIGN_PARAGRAPH.LEFT

            lines = text.split("\n")
            for line_idx, line in enumerate(lines):
                if line_idx > 0:
                    p = cell.add_paragraph()
                    p.paragraph_format.space_before = Pt(2)
                    p.paragraph_format.space_after = Pt(0)
                    p.paragraph_format.line_spacing = 1.15
                    if col_idx == 0 and row_idx > 0:
                        p.alignment = WD_ALIGN_PARAGRAPH.CENTER

                run = p.add_run(line)
                run.font.name = "Calibri"
                if row_idx == 0:
                    run.bold = True
                    run.font.size = Pt(10)
                    run.font.color.rgb = RGBColor(255, 255, 255)
                else:
                    run.font.size = Pt(9.5)
                    if col_idx == 0 or (col_idx == 1 and row_idx > 0):
                        run.bold = True
                    run.font.color.rgb = RGBColor(15, 23, 42)

    # Spacer
    p_sp = doc.add_paragraph()
    p_sp.paragraph_format.space_before = Pt(14)
    p_sp.paragraph_format.space_after = Pt(0)

    # SECTION 2
    p_h2 = doc.add_paragraph()
    p_h2.paragraph_format.space_before = Pt(10)
    p_h2.paragraph_format.space_after = Pt(6)
    r_h2 = p_h2.add_run("PHẦN 2: CHI TIẾT TỪNG NỘI DUNG ĐỂ HỌC VÀ TRẢ LỜI VẤN ĐÁP")
    r_h2.font.name = "Segoe UI"
    r_h2.font.size = Pt(14)
    r_h2.bold = True
    r_h2.font.color.rgb = RGBColor(2, 132, 199)

    # TOPIC 1
    p_t1 = doc.add_paragraph()
    p_t1.paragraph_format.space_before = Pt(8)
    p_t1.paragraph_format.space_after = Pt(4)
    r_t1 = p_t1.add_run("1. EVENT LOOP & MICROTASK QUEUE")
    r_t1.font.name = "Segoe UI"
    r_t1.font.size = Pt(12)
    r_t1.bold = True
    r_t1.font.color.rgb = RGBColor(15, 118, 110)

    doc.add_paragraph(
        "• Bản chất lý thuyết:\n"
        "  - Dart là ngôn ngữ đơn luồng (Single-threaded): Trong một Isolate, tại một thời điểm chỉ có 1 tác vụ được CPU xử lý trên Call Stack.\n"
        "  - Để không bị đứng máy (ANR/Freeze) khi xử lý việc nặng hay chờ mạng, Dart sử dụng cơ chế Event Loop điều phối 2 hàng đợi:\n"
        "    1. Microtask Queue: Chứa các tác vụ khẩn cấp nội bộ (được gọi qua scheduleMicrotask() hoặc Future.microtask()).\n"
        "    2. Event Queue: Chứa các sự kiện bên ngoài như: người dùng chạm màn hình (I/O), sự kiện Timer (Timer.periodic), phản hồi mạng (Future, Stream).\n"
        "  - QUY TẮC VÀNG: Mã đồng bộ (Call Stack) -> Hút cạn sạch Microtask Queue -> Bốc 1 tác vụ từ Event Queue. Microtask luôn luôn được giải quyết hết trước khi chạm tới Event Queue!"
    )

    add_callout(doc, [
        "**Vị trí trong mã nguồn đồ án:**",
        "• **lib/main.dart** (Dòng 22 - 24): Gọi scheduleMicrotask() ngay khi app vừa khởi động.",
        "• **lib/services/event_loop_simulator_service.dart** (Dòng 47 - 126): Hàm runExperiment() lên lịch đồng thời: Sync Stack, Event Queue (Future), Microtask Queue để chứng minh thứ tự ưu tiên.",
        "• **test/event_loop_order_test.dart**: Bộ unit test tự động xác nhận Microtask luôn chạy trước Future."
    ], bg_hex="FEF2F2", border_hex="DC2626")

    add_code_block(doc, 
        "// Trích đoạn lib/main.dart (Dòng 22-24):\n"
        "scheduleMicrotask(() {\n"
        "  debugPrint('[EVENT_LOOP] Microtask được thực thi trong quá trình khởi động ứng dụng.');\n"
        "});"
    )

    add_callout(doc, [
        "**Mẫu câu trả lời Thầy/Cô khi được hỏi:**",
        "\"Dạ thưa Thầy/Cô, nhóm em chứng minh cơ chế Event Loop trực quan tại Tab 3: 'Phòng Thí Nghiệm Event Loop'. Khi bấm chạy thử nghiệm, Thầy/Cô sẽ thấy mã Đồng bộ chạy đầu tiên, tiếp theo là Microtask Queue dù lên lịch sau nhưng vẫn được Event Loop ưu tiên giải quyết sạch sẽ trước, rồi cuối cùng các Future trong Event Queue mới được thực thi.\""
    ], bg_hex="F0FDF4", border_hex="16A34A")

    # TOPIC 2
    p_t2 = doc.add_paragraph()
    p_t2.paragraph_format.space_before = Pt(12)
    p_t2.paragraph_format.space_after = Pt(4)
    r_t2 = p_t2.add_run("2. FUTURE & ASYNC / AWAIT")
    r_t2.font.name = "Segoe UI"
    r_t2.font.size = Pt(12)
    r_t2.bold = True
    r_t2.font.color.rgb = RGBColor(15, 118, 110)

    doc.add_paragraph(
        "• Bản chất lý thuyết:\n"
        "  - Future<T>: Đại diện cho duy nhất một giá trị (hoặc một ngoại lệ lỗi) sẽ xuất hiện trong tương lai sau một khoảng thời gian chờ đợi.\n"
        "  - async: Từ khóa đánh dấu một hàm là bất đồng bộ và luôn trả về một Future.\n"
        "  - await: Tạm dừng việc thực thi hàm async hiện tại cho đến khi Future hoàn tất, nhưng không hề làm block luồng chính (giao diện vẫn mượt mà 60 FPS)."
    )

    add_callout(doc, [
        "**Vị trí trong mã nguồn đồ án:**",
        "• **lib/services/crypto_price_stream_service.dart** (Dòng 263, 369, 378): Các hàm async / await kết nối Binance WebSocket, chuyển đổi nguồn dữ liệu, và giải phóng bộ nhớ.",
        "• **lib/services/event_loop_simulator_service.dart** (Dòng 65, 76, 129): Sử dụng await Future.delayed() để đồng bộ thứ tự hiển thị hoạt họa."
    ], bg_hex="FEF2F2", border_hex="DC2626")

    add_code_block(doc,
        "// Trích đoạn lib/services/crypto_price_stream_service.dart:\n"
        "Future<void> connectToBinance() async {\n"
        "  pauseSimulation();\n"
        "  // Mở kết nối WebSocket thời gian thực tới Binance...\n"
        "}\n\n"
        "Future<void> toggleDataSource() async {\n"
        "  if (_currentMode == DataSourceMode.simulation) {\n"
        "    await connectToBinance();\n"
        "  } else {\n"
        "    switchToSimulation();\n"
        "  }\n"
        "}"
    )

    add_callout(doc, [
        "**Mẫu câu trả lời Thầy/Cô khi được hỏi:**",
        "\"Dạ thưa Thầy/Cô, nhóm em sử dụng async/await ở các tác vụ chỉ cần thực hiện 1 lần và có độ trễ, tiêu biểu như hàm toggleDataSource() để kết nối WebSocket của Binance hoặc hàm dispose() để đóng tài nguyên. Khác với Future chỉ trả về 1 kết quả duy nhất, luồng giá biến động liên tục của sàn lại được nhóm em xử lý bằng Stream.\""
    ], bg_hex="F0FDF4", border_hex="16A34A")

    # TOPIC 3
    p_t3 = doc.add_paragraph()
    p_t3.paragraph_format.space_before = Pt(12)
    p_t3.paragraph_format.space_after = Pt(4)
    r_t3 = p_t3.add_run("3. CƠ CHẾ STREAM & STREAMCONTROLLER")
    r_t3.font.name = "Segoe UI"
    r_t3.font.size = Pt(12)
    r_t3.bold = True
    r_t3.font.color.rgb = RGBColor(15, 118, 110)

    doc.add_paragraph(
        "• Bản chất lý thuyết:\n"
        "  - Stream: Là một dòng chảy dữ liệu bất đồng bộ liên tục theo thời gian (chứa 0, 1 hoặc nhiều sự kiện). Giống như một đường ống dẫn, dữ liệu đi vào đầu này và bắn ra ở đầu kia.\n"
        "  - StreamController: Là đối tượng điều khiển luồng, cung cấp Sink (đầu vào: controller.add(data)) và Stream (đầu ra: controller.stream.listen()).\n"
        "  - Quản lý vòng đời (Lifecycle): Cung cấp các callback onListen và onCancel giúp đếm số lượng widget đang lắng nghe và tự động tắt timer để tránh Memory Leak."
    )

    add_callout(doc, [
        "**Vị trí trong mã nguồn đồ án:**",
        "• **lib/services/crypto_price_stream_service.dart** (Dòng 35, 41, 68 - 80, 248, 342): Định nghĩa StreamController, callback onListen/onCancel, và đẩy dữ liệu qua _priceStreamController.add(tick).",
        "• **lib/services/order_book_stream_service.dart** (Dòng 9, 17, 71): Stream sổ lệnh Mua/Bán sinh tự động mỗi 900ms.",
        "• **lib/views/crypto_market_screen.dart** (Dòng 24, 38): Quản lý luồng tìm kiếm _searchQueryController."
    ], bg_hex="FEF2F2", border_hex="DC2626")

    add_code_block(doc,
        "// Trích đoạn lib/services/crypto_price_stream_service.dart (Dòng 68-80):\n"
        "_priceStreamController = StreamController<MarketTick>.broadcast(\n"
        "  onListen: () {\n"
        "    _activeListenersCount++;\n"
        "    _listenerTrackerController.add(_activeListenersCount);\n"
        "  },\n"
        "  onCancel: () {\n"
        "    if (_activeListenersCount > 0) _activeListenersCount--;\n"
        "    _listenerTrackerController.add(_activeListenersCount);\n"
        "  },\n"
        ");"
    )

    # TOPIC 4
    p_t4 = doc.add_paragraph()
    p_t4.paragraph_format.space_before = Pt(12)
    p_t4.paragraph_format.space_after = Pt(4)
    r_t4 = p_t4.add_run("4. BROADCAST STREAM (PHÁT ĐA HƯỚNG)")
    r_t4.font.name = "Segoe UI"
    r_t4.font.size = Pt(12)
    r_t4.bold = True
    r_t4.font.color.rgb = RGBColor(15, 118, 110)

    doc.add_paragraph(
        "• Bản chất lý thuyết:\n"
        "  - Single-Subscription Stream (Mặc định): Chỉ cho phép duy nhất 1 listener lắng nghe. Nếu có đối tượng thứ 2 cố lắng nghe sẽ throw lỗi StateError: Stream has already been listened to.\n"
        "  - Broadcast Stream: Cho phép nhiều đối tượng (multi-subscriber) độc lập cùng lắng nghe một luồng dữ liệu mà không xung đột. Mỗi listener có thể ngắt kết nối mà không ảnh hưởng tới các listener khác."
    )

    add_callout(doc, [
        "**Vị trí trong mã nguồn đồ án:**",
        "• **Khởi tạo Broadcast:** lib/services/crypto_price_stream_service.dart (Dòng 68): StreamController<MarketTick>.broadcast().",
        "• **Listener 1 (Trang chủ thị trường):** lib/views/crypto_market_screen.dart (Dòng 176): Dùng StreamBuilder lắng nghe service.marketStream để cập nhật danh sách giá coin.",
        "• **Listener 2 (Trang chi tiết coin):** lib/views/crypto_detail_screen.dart (Dòng 83): Lắng nghe đồng thời để cập nhật biểu đồ nến và giá chi tiết."
    ], bg_hex="FEF2F2", border_hex="DC2626")

    add_callout(doc, [
        "**Mẫu câu trả lời Thầy/Cô khi được hỏi:**",
        "\"Dạ thưa Thầy/Cô, trong ứng dụng tài chính CryptoPulse, giá của Bitcoin vừa phải hiển thị ở thẻ danh sách ngoài trang chủ, vừa phải cập nhật biểu đồ ở màn hình chi tiết, vừa phải phục vụ bộ đếm Active Listeners trên thanh Header. Nếu dùng Stream đơn lẻ thông thường thì app sẽ crash ngay khi người dùng chuyển trang. Do đó, nhóm em cấu hình StreamController.broadcast() để phục vụ mô hình đa điểm phát này.\""
    ], bg_hex="F0FDF4", border_hex="16A34A")

    # TOPIC 5
    p_t5 = doc.add_paragraph()
    p_t5.paragraph_format.space_before = Pt(12)
    p_t5.paragraph_format.space_after = Pt(4)
    r_t5 = p_t5.add_run("5. CÁC TOÁN TỬ BIẾN ĐỔI DỮ LIỆU (DEBOUNCE, THROTTLE, WHERE)")
    r_t5.font.name = "Segoe UI"
    r_t5.font.size = Pt(12)
    r_t5.bold = True
    r_t5.font.color.rgb = RGBColor(15, 118, 110)

    doc.add_paragraph(
        "• Bản chất lý thuyết:\n"
        "  - where (Lọc): Chỉ cho phép các phần tử thỏa mãn điều kiện logic đi qua luồng.\n"
        "  - debounce (Chống dội): Trì hoãn phát sự kiện. Chỉ khi nào nguồn phát ngừng bắn dữ liệu liên tục trong một khoảng thời gian (ví dụ 400ms) thì mới phát sự kiện cuối cùng. Rất hữu ích cho ô tìm kiếm để tránh gửi request dư thừa.\n"
        "  - throttle (Tiết lưu): Phát sự kiện đầu tiên ngay lập tức, sau đó chặn toàn bộ các sự kiện tiếp theo trong một khoảng thời gian (ví dụ 300ms). Tránh nghẽn GPU khi luồng giá nhảy hàng trăm lần mỗi giây."
    )

    add_callout(doc, [
        "**Vị trí trong mã nguồn đồ án:**",
        "• **lib/core/transformers/stream_transformers.dart**: Tự xây dựng DebounceStreamTransformer (Dòng 5-61) và ThrottleStreamTransformer (Dòng 65-117) kế thừa từ StreamTransformerBase của Dart SDK.",
        "• **Debounce 400ms (Ô tìm kiếm Coin):** lib/views/crypto_market_screen.dart (Dòng 38-47).",
        "• **Throttle 300ms (Trang chi tiết):** lib/views/crypto_detail_screen.dart (Dòng 85).",
        "• **Where (Lọc theo mã coin):** lib/services/crypto_price_stream_service.dart (Dòng 253-255)."
    ], bg_hex="FEF2F2", border_hex="DC2626")

    add_code_block(doc,
        "// Áp dụng Debounce 400ms ở ô tìm kiếm (lib/views/crypto_market_screen.dart):\n"
        "_searchSubscription = _searchQueryController.stream\n"
        "    .debounce(const Duration(milliseconds: 400))\n"
        "    .listen((query) {\n"
        "      setState(() {\n"
        "        _currentQuery = query.trim().toLowerCase();\n"
        "      });\n"
        "    });"
    )

    # SECTION 3
    p_h3 = doc.add_paragraph()
    p_h3.paragraph_format.space_before = Pt(14)
    p_h3.paragraph_format.space_after = Pt(6)
    r_h3 = p_h3.add_run("PHẦN 3: KỊCH BẢN THỰC HÀNH “CHỈ TAY VÀO MÀN HÌNH” TRƯỚC HỘI ĐỒNG")
    r_h3.font.name = "Segoe UI"
    r_h3.font.size = Pt(14)
    r_h3.bold = True
    r_h3.font.color.rgb = RGBColor(2, 132, 199)

    p_guide_intro = doc.add_paragraph()
    p_guide_intro.paragraph_format.space_before = Pt(0)
    p_guide_intro.paragraph_format.space_after = Pt(8)
    r_gi = p_guide_intro.add_run("Khi Thầy/Cô yêu cầu: ")
    r_gi.font.name = "Calibri"
    r_gi.font.size = Pt(11)
    r_gi_quote = p_guide_intro.add_run('“Bây giờ em hãy thực hiện demo chứng minh 5 nội dung này ngay trên phần mềm đang chạy!”')
    r_gi_quote.italic = True
    r_gi_quote.bold = True
    r_gi_quote.font.color.rgb = RGBColor(15, 23, 42)
    r_gi_quote.font.size = Pt(11)
    r_gi_end = p_guide_intro.add_run(", các bạn làm lần lượt 4 bước sau:")
    r_gi_end.font.size = Pt(11)

    steps = [
        "**Bước 1: Chứng minh Stream & Broadcast Stream**\n"
        "• Mở Trang chủ thị trường: Chỉ vào các thẻ Coin thấy giá và phần trăm nhảy liên tục từng giây không cần bấm nút tải lại trang -> Giải thích: “Đây là Stream thời gian thực”.\n"
        "• Bấm vào xem chi tiết đồng Bitcoin: Chỉ cho Thầy/Cô thấy cả 2 nơi (Header trang chủ và Màn hình chi tiết) đều nhận dữ liệu đồng thời -> Giải thích: “Đây là Broadcast Stream đa điểm phát”.",

        "**Bước 2: Chứng minh Toán tử Debounce**\n"
        "• Tại ô Tìm kiếm ở Trang chủ: Gõ thật nhanh từ khóa “BITCOIN”.\n"
        "• Chỉ vào vòng xoay nhỏ đang chờ: Trong lúc tay đang gõ, app chưa lọc ngay mà chờ đúng 400ms sau khi ngừng gõ mới tiến hành lọc danh sách -> Giải thích: “Đây là toán tử Debounce giúp giảm tải việc lọc liên tục”.",

        "**Bước 3: Chứng minh Event Loop & Microtask Queue**\n"
        "• Chuyển sang Tab 3: Phòng Thí Nghiệm Event Loop.\n"
        "• Bấm nút “Chạy Thử Nghiệm Mô Phỏng”.\n"
        "• Chỉ vào thứ tự các hộp màu xuất hiện: 1. Đồng bộ (Sync) -> 2. Microtask Queue -> 3. Event Queue (Future) -> Giải thích: “Event Loop luôn vét sạch Microtask trước khi lấy tác vụ từ Event Queue”.",

        "**Bước 4: Chứng minh Kết nối WebSocket Live Quốc tế**\n"
        "• Trên thanh AppBar, bấm vào nút màu vàng “BINANCE LIVE”.\n"
        "• Trạng thái đổi sang màu xanh “BINANCE LIVE (WEBSOCKET)”. Giá các đồng coin nhảy theo đúng sàn Binance thế giới thật 100% -> Giải thích: “Nhóm em kết nối WebSocket bất đồng bộ qua mạng Internet thật”."
    ]

    for step in steps:
        add_callout(doc, step.split("\n"), bg_hex="F8FAFC", border_hex="0284C7")

    doc.save(output_path)
    print("Successfully generated Word docx!")

if __name__ == "__main__":
    out_dir_1 = r"D:\reactive_crypto_tracker"
    out_dir_2 = r"c:\Users\Admin\Downloads\viết và thuyết trình kỹ thuật\reactive_crypto_tracker"
    
    out_file_1 = os.path.join(out_dir_1, "TAI_LIEU_ON_TAP_WORD.docx")
    out_file_2 = os.path.join(out_dir_2, "TAI_LIEU_ON_TAP_WORD.docx")
    
    generate_doc(out_file_1)
    generate_doc(out_file_2)
