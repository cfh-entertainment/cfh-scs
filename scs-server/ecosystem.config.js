module.exports = {
  apps: [
    {
      name: 'scs-server',
      script: 'src/index.js',
      // automatisch neu starten bei Code-Änderungen (Entwicklung)
      watch: true,
      // Umgebungsvariablen
      log_date_format: 'YYYY-MM-DD HH:mm Z',
      // eigene Log-Pfade:
      output: '/home/cfh/logs/scs-server-out.log',
      error:  '/home/cfh/logs/scs-server-error.log',
      env: {
        NODE_ENV: 'development',
        PORT: 3000
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 3000
      }
    }
  ]
};

