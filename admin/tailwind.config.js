/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        primary: { 50: '#FFF1F1', 500: '#8B0000', 600: '#6B0000', 900: '#3B0000' },
      },
    },
  },
  plugins: [],
};
