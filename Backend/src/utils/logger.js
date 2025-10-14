/**
 * Simple Logger Utility
 */

export const logger = {
  info: (message, ...args) => {
    console.log(`ℹ️  ${message}`, ...args);
  },
  
  success: (message, ...args) => {
    console.log(`✅ ${message}`, ...args);
  },
  
  warning: (message, ...args) => {
    console.warn(`⚠️  ${message}`, ...args);
  },
  
  error: (message, ...args) => {
    console.error(`❌ ${message}`, ...args);
  },
  
  download: (message, ...args) => {
    console.log(`📥 ${message}`, ...args);
  },
  
  torrent: (message, ...args) => {
    console.log(`🎬 ${message}`, ...args);
  },
  
  progress: (message) => {
    process.stdout.write(`\r${message}`);
  },
  
  newLine: () => {
    console.log('');
  }
};
