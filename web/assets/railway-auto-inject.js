// این کد به صورت خودکار به UI تزریق می‌شود
(function() {
    'use strict';
    
    // صبر می‌کنیم تا DOM لود شود
    function injectRailwayButton() {
        // پیدا کردن منوی Inbounds در UI اصلی vpn-ui
        const sidebar = document.querySelector('.ant-menu, .el-menu, [class*="sidebar"], [class*="menu"]');
        if (!sidebar) {
            setTimeout(injectRailwayButton, 1000);
            return;
        }
        
        // اگر دکمه قبلاً تزریق شده، کاری نکن
        if (document.getElementById('railway-auto-btn')) return;
        
        // ساخت دکمه جدید
        const btn = document.createElement('button');
        btn.id = 'railway-auto-btn';
        btn.innerHTML = '🚀 ساخت خودکار کانفیگ Railway';
        btn.style.cssText = `
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 8px;
            font-size: 14px;
            font-weight: bold;
            cursor: pointer;
            margin: 20px auto;
            display: block;
            width: 90%;
            box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
            transition: all 0.3s ease;
        `;
        
        btn.onmouseover = () => btn.style.transform = 'translateY(-2px)';
        btn.onmouseout = () => btn.style.transform = 'translateY(0)';
        
        btn.onclick = showRailwayModal;
        
        sidebar.appendChild(btn);
    }
    
    function showRailwayModal() {
        // ساخت مودال انتخاب پروتکل
        const modal = document.createElement('div');
        modal.innerHTML = `
            <div style="position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.7); z-index: 9999; display: flex; align-items: center; justify-content: center;">
                <div style="background: white; padding: 30px; border-radius: 12px; max-width: 500px; width: 90%;">
                    <h2 style="margin-top: 0; color: #333;">🚀 ساخت خودکار کانفیگ Railway</h2>
                    <p style="color: #666;">پروتکل مورد نظر خود را انتخاب کنید. بقیه تنظیمات به صورت اتوماتیک و بهینه برای Railway تولید می‌شود.</p>
                    
                    <div style="display: grid; gap: 12px; margin: 20px 0;">
                        <label style="display: flex; align-items: center; padding: 15px; border: 2px solid #e0e0e0; border-radius: 8px; cursor: pointer;">
                            <input type="radio" name="protocol" value="vless-ws" checked style="margin-right: 12px;">
                            <div>
                                <strong>VLESS + WebSocket</strong>
                                <div style="font-size: 12px; color: #999;">بهترین سازگاری با Railway و Cloudflare</div>
                            </div>
                        </label>
                        
                        <label style="display: flex; align-items: center; padding: 15px; border: 2px solid #e0e0e0; border-radius: 8px; cursor: pointer;">
                            <input type="radio" name="protocol" value="vless-reality" style="margin-right: 12px;">
                            <div>
                                <strong>VLESS + REALITY</strong>
                                <div style="font-size: 12px; color: #999;">پیشرفته‌ترین پروتکل، غیرقابل تشخیص</div>
                            </div>
                        </label>
                        
                        <label style="display: flex; align-items: center; padding: 15px; border: 2px solid #e0e0e0; border-radius: 8px; cursor: pointer;">
                            <input type="radio" name="protocol" value="vless-xhttp" style="margin-right: 12px;">
                            <div>
                                <strong>VLESS + XHTTP</strong>
                                <div style="font-size: 12px; color: #999;">پروتکل جدید با عملکرد بالا</div>
                            </div>
                        </label>
                    </div>
                    
                    <div style="display: flex; gap: 10px;">
                        <button id="railway-cancel" style="flex: 1; padding: 12px; border: 1px solid #ddd; background: white; border-radius: 8px; cursor: pointer;">انصراف</button>
                        <button id="railway-confirm" style="flex: 1; padding: 12px; border: none; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border-radius: 8px; cursor: pointer; font-weight: bold;">تولید کانفیگ</button>
                    </div>
                </div>
            </div>
        `;
        
        document.body.appendChild(modal);
        
        document.getElementById('railway-cancel').onclick = () => modal.remove();
        document.getElementById('railway-confirm').onclick = () => {
            const protocol = document.querySelector('input[name="protocol"]:checked').value;
            generateRailwayConfig(protocol, modal);
        };
    }
    
    async function generateRailwayConfig(protocol, modal) {
        const domain = window.location.hostname;
        
        try {
            const response = await fetch('/api/railway-auto', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ protocol, domain })
            });
            
            const result = await response.json();
            
            if (result.success) {
                modal.remove();
                showSuccessModal(result.obj, protocol);
            } else {
                alert('خطا در تولید کانفیگ: ' + (result.error || 'خطای ناشناخته'));
            }
        } catch (error) {
            alert('خطا در ارتباط با سرور: ' + error.message);
        }
    }
    
    function showSuccessModal(config, protocol) {
        const clientConfig = config.client_config;
        const vlessLink = `vless://${config.uuid}@${window.location.hostname}:${clientConfig.port}?encryption=none&security=${clientConfig.security}&sni=${clientConfig.sni}&fp=${clientConfig.fp}&type=${clientConfig.type}&host=${clientConfig.host}&path=${encodeURIComponent(clientConfig.path)}#Railway-${protocol}`;
        
        const modal = document.createElement('div');
        modal.innerHTML = `
            <div style="position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.7); z-index: 9999; display: flex; align-items: center; justify-content: center;">
                <div style="background: white; padding: 30px; border-radius: 12px; max-width: 600px; width: 90%;">
                    <h2 style="margin-top: 0; color: #27ae60;">✅ کانفیگ با موفقیت تولید شد!</h2>
                    
                    <div style="background: #f5f5f5; padding: 15px; border-radius: 8px; margin: 20px 0;">
                        <strong>UUID:</strong> ${config.uuid}<br>
                        <strong>Port (Internal):</strong> ${config.port}<br>
                        <strong>Network:</strong> ${config.network}<br>
                        <strong>Security:</strong> ${config.security}
                    </div>
                    
                    <h3>📋 لینک اتصال (کپی کنید):</h3>
                    <textarea readonly style="width: 100%; height: 80px; padding: 10px; border: 1px solid #ddd; border-radius: 6px; font-family: monospace; font-size: 11px;">${vlessLink}</textarea>
                    
                    <div style="display: flex; gap: 10px; margin-top: 20px;">
                        <button onclick="navigator.clipboard.writeText('${vlessLink}'); this.textContent='کپی شد!'" style="flex: 1; padding: 12px; border: none; background: #27ae60; color: white; border-radius: 8px; cursor: pointer; font-weight: bold;">کپی لینک</button>
                        <button onclick="this.closest('div[style*=fixed]').remove()" style="flex: 1; padding: 12px; border: 1px solid #ddd; background: white; border-radius: 8px; cursor: pointer;">بستن</button>
                    </div>
                    
                    <p style="font-size: 12px; color: #999; margin-top: 20px;">
                        <strong>⚠️ توجه:</strong> این کانفیگ به صورت اتوماتیک به لیست Inbounds اضافه نشده است. لطفاً مقادیر بالا را به صورت دستی در بخش Inbounds وارد کنید یا از لینک تولید شده در کلاینت خود استفاده کنید.
                    </p>
                </div>
            </div>
        `;
        
        document.body.appendChild(modal);
    }
    
    // شروع تزریق
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', injectRailwayButton);
    } else {
        injectRailwayButton();
    }
})();
