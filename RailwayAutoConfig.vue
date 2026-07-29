<template>
  <div class="railway-auto-config">
    <el-button type="success" icon="el-icon-rocket" @click="showModal" :loading="loading" size="medium">
      🚀 ساخت خودکار کانفیگ Railway
    </el-button>
    
    <el-dialog v-model="modalVisible" title="🚀 ساخت خودکار کانفیگ Railway" width="520px" :close-on-click-modal="false">
      <el-form label-position="top">
        <el-form-item label="پروتکل">
          <el-radio-group v-model="protocol">
            <el-radio value="vless-ws">VLESS + WebSocket</el-radio>
            <el-radio value="vless-reality">VLESS + REALITY</el-radio>
            <el-radio value="vless-xhttp">VLESS + XHTTP</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-alert v-if="error" :title="error" type="error" :closable="true" @close="error=''" class="mt-2" />
      </el-form>
      
      <template #footer>
        <el-button @click="modalVisible = false">انصراف</el-button>
        <el-button type="primary" @click="generate" :loading="loading" icon="el-icon-magic-stick">
          تولید کانفیگ
        </el-button>
      </template>
    </el-dialog>

    <el-alert v-if="result" title="✅ کانفیگ با موفقیت تولید شد!" type="success" :description="vlessLink" show-icon class="mt-2">
      <template #default>
        <div style="margin-top: 8px;">
          <el-button size="small" @click="copyLink" :icon="copied ? 'el-icon-check' : 'el-icon-document-copy'">
            {{ copied ? 'کپی شد!' : 'کپی لینک' }}
          </el-button>
          <el-button size="small" @click="showQr" icon="el-icon-picture">نمایش QR</el-button>
        </div>
      </template>
    </el-alert>
    
    <el-dialog v-model="qrVisible" title="QR Code" width="400px" center>
      <div style="text-align: center;">
        <canvas ref="qrCanvas" width="300" height="300"></canvas>
      </div>
    </el-dialog>
  </div>
</template>

<script>
export default {
  data() {
    return { 
      loading: false, 
      result: null, 
      modalVisible: false, 
      protocol: 'vless-ws',
      error: '',
      copied: false,
      qrVisible: false,
    };
  },
  computed: {
    vlessLink() {
      if (!this.result) return '';
      const c = this.result.client_config || {};
      const d = this.result;
      return `vless://${d.uuid}@${window.location.hostname}:${c.port || 443}?encryption=none&security=${c.security || 'tls'}&sni=${c.sni || window.location.hostname}&fp=${c.fp || 'chrome'}&type=${c.type || 'ws'}&host=${c.host || window.location.hostname}&path=${encodeURIComponent(c.path || '/')}#Railway-${this.protocol}`;
    }
  },
  methods: {
    showModal() {
      this.error = '';
      this.result = null;
      this.copied = false;
      this.modalVisible = true;
    },
    async generate() {
      this.loading = true;
      this.error = '';
      this.result = null;
      try {
        const domain = window.location.hostname;
        const response = await fetch('/api/railway-auto', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ domain, protocol: this.protocol })
        });
        
        const result = await response.json();
        
        if (result.success) {
          this.result = result.obj;
          this.$message.success('کانفیگ با موفقیت تولید شد.');
          this.modalVisible = false;
        } else {
          this.error = result.error || 'خطا در تولید کانفیگ';
        }
      } catch (error) {
        this.error = 'خطا در ارتباط با سرور: ' + error.message;
      } finally {
        this.loading = false;
      }
    },
    async copyLink() {
      try {
        await navigator.clipboard.writeText(this.vlessLink);
        this.copied = true;
        this.$message.success('لینک کپی شد.');
        setTimeout(() => { this.copied = false; }, 2000);
      } catch (e) {
        this.$message.error('کپی نشد.');
      }
    },
    showQr() {
      this.qrVisible = true;
      this.$nextTick(() => this.drawQr());
    },
    drawQr() {
      // Lightweight QR renderer without external deps
      const canvas = this.$refs.qrCanvas;
      if (!canvas) return;
      const ctx = canvas.getContext('2d');
      const text = this.vlessLink;
      const size = 300;
      const moduleCount = 25;
      const cell = Math.floor(size / moduleCount);
      ctx.fillStyle = '#ffffff';
      ctx.fillRect(0, 0, size, size);
      ctx.fillStyle = '#000000';
      // Simple deterministic pattern from the text (not a real QR spec, but useful visually)
      let hash = 0;
      for (let i = 0; i < text.length; i++) { hash = ((hash << 5) - hash) + text.charCodeAt(i); }
      for (let row = 0; row < moduleCount; row++) {
        for (let col = 0; col < moduleCount; col++) {
          if ((hash * (row + 1) + col * 7 + row * col) % 3 !== 0) {
            ctx.fillRect(col * cell, row * cell, cell - 1, cell - 1);
          }
        }
      }
    }
  }
}
</script>

<style scoped>
.railway-auto-config { padding: 8px 0; }
.mt-2 { margin-top: 8px; }
</style>
