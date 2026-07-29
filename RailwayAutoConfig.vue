<template>
  <div class="railway-auto-config">
    <el-button type="success" icon="el-icon-rocket" @click="generateRailwayConfig" :loading="loading">
      🚀 ساخت خودکار کانفیگ بهینه برای ریلوی
    </el-button>
    <el-alert v-if="generatedLink" title="کانفیگ با موفقیت ساخته شد!" type="success" :description="generatedLink" show-icon class="mt-2" />
  </div>
</template>

<script>
export default {
  data() {
    return { loading: false, generatedLink: '' };
  },
  methods: {
    async generateRailwayConfig() {
      this.loading = true;
      try {
        const domain = window.location.hostname;
        // فرض بر این است که این اندپوینت را در بک‌اند اضافه کرده‌اید
        const response = await this.$http.post('/panel/inbound/railway-auto', { domain });
        
        if (response.success) {
          const data = response.obj;
          this.generatedLink = `vless://${data.uuid}@${domain}:443?encryption=none&security=tls&sni=${domain}&fp=chrome&type=ws&host=${domain}&path=${encodeURIComponent(data.path)}#Railway-AutoConfig`;
          this.$message.success('اینباند با موفقیت ایجاد و لینک تولید شد.');
          this.$emit('refresh-inbounds');
        }
      } catch (error) {
        this.$message.error('خطا در ساخت کانفیگ: ' + error.message);
      } finally {
        this.loading = false;
      }
    }
  }
}
</script>
