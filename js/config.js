export const APP_CONFIG = {
  name: "Ponto Eletrônico",
  version: "0.1.0",

  supabase: {
    url: "",
    anonKey: ""
  },

  terminal: {
    id: localStorage.getItem("terminal_id") || "TERMINAL-001",
    name: localStorage.getItem("terminal_name") || "Terminal Principal"
  },

  rules: {
    eventToleranceMinutes: 5,
    dailyToleranceMinutes: 10
  }
};
