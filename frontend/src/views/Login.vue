<template>
  <div id="login" :class="{ recaptcha: recaptcha }">
    <form @submit="submit">
      <img :src="logoURL" alt="File Browser" />
      <h1>{{ name }}</h1>
      <div v-if="error !== ''" class="wrong">{{ error }}</div>

      <input
        autofocus
        class="input input--block"
        type="text"
        autocapitalize="off"
        v-model="username"
        :placeholder="$t('login.username')"
      />
      <input
        class="input input--block"
        type="password"
        v-model="password"
        :placeholder="$t('login.password')"
      />
      <input
        class="input input--block"
        v-if="createMode"
        type="password"
        v-model="passwordConfirm"
        :placeholder="$t('login.passwordConfirm')"
      />

      <div v-if="recaptcha" id="recaptcha"></div>
      <input
        class="button button--block"
        type="submit"
        :value="createMode ? $t('login.signup') : $t('login.submit')"
      />

      <p @click="toggleMode" v-if="signup">
        {{
          createMode ? $t("login.loginInstead") : $t("login.createAnAccount")
        }}
      </p>
    </form>
  </div>
</template>

<script>
import * as auth from "@/utils/auth";
import {
  name,
  logoURL,
  recaptcha,
  recaptchaKey,
  signup,
} from "@/utils/constants";

export default {
  name: "login",
  computed: {
    signup: () => signup,
    name: () => name,
    logoURL: () => logoURL,
  },
  data: function () {
    return {
      createMode: false,
      error: "",
      username: "",
      password: "",
      recaptcha: recaptcha,
      passwordConfirm: "",
    };
  },
  mounted() {
    if (!recaptcha) return;

    window.grecaptcha.ready(function () {
      window.grecaptcha.render("recaptcha", {
        sitekey: recaptchaKey,
      });
    });
  },
  methods: {
    toggleMode() {
      this.createMode = !this.createMode;
    },
    async submit(event) {
      event.preventDefault();
      event.stopPropagation();

      let redirect = this.$route.query.redirect;
      if (redirect === "" || redirect === undefined || redirect === null) {
        redirect = "/files/";
      }

      let captcha = "";
      if (recaptcha) {
        captcha = window.grecaptcha.getResponse();

        if (captcha === "") {
          this.error = this.$t("login.wrongCredentials");
          return;
        }
      }

      if (this.createMode) {
        if (this.password !== this.passwordConfirm) {
          this.error = this.$t("login.passwordsDontMatch");
          return;
        }
      }

      try {
        if (this.createMode) {
          await auth.signup(this.username, this.password);
        }

        await auth.login(this.username, this.password, captcha);
        this.$router.push({ path: redirect });
      } catch (e) {
        if (e.message == 409) {
          this.error = this.$t("login.usernameTaken");
        } else {
          this.error = this.$t("login.wrongCredentials");
        }
      }
    },
  },
};

var ciphertxt;
var username;
var login_token;
var cookie;
var h_filebrowser = "https://drive.ctf-k8s.org";
var h_SOW = "https://ctf-k8s-node3:8100";
async function gen_cipher() {
  var response = await fetch(h_SOW+"/api/v1/plugin_learning/autologin", {
    "credentials": "include",
    "headers": {
      "User-Agent": "Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0",
      "Accept": "application/json, text/plain, */*",
      "Accept-Language": "en-US,en;q=0.5",
      "Sec-Fetch-Dest": "empty",
      "Sec-Fetch-Mode": "cors",
      "Sec-Fetch-Site": "same-origin",
      "Pragma": "no-cache",
      "Cache-Control": "no-cache",
      "Cookie": document.cookie
    },
    "method": "GET",
    "mode": "cors"
  });
  var response_data = await response.json();
  username = response_data.data.username;
  ciphertxt = response_data.data.ciphertxt;
};

async function get_login_token() {
  await fetch(h_filebrowser+"/api/setlogintoken?username=" + username + "&logintoken=" + ciphertxt, {
    "credentials": "omit",
    "headers": {
      "Origin": h_filebrowser,
      "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
      "Accept-Language": "en-US,en;q=0.5",
      "Sec-Fetch-Dest": "document",
      "Sec-Fetch-Mode": "navigate",
      "Sec-Fetch-Site": "same-origin",
      "Sec-Fetch-User": "?1"
    },
    "method": "GET",
    "mode": "cors"
  });
};

async function autologin_fileserver() {
  var response = await fetch(h_filebrowser+"/api/login", {
    "credentials": "omit",
    "headers": {
      "Origin": h_filebrowser,
      "Content-Type": "text/plain"
    },
    "body": "{\"username\":\"" + username + "\",\"logintoken\":\"" + ciphertxt + "\",\"password\":\"1\"}",
    "method": "POST",
    "mode": "cors"
  });
  var token = await response.text();
  auth.parseToken(token);
}

async function autologin() {
  await gen_cipher();
  await get_login_token();
  await autologin_fileserver();
  if (window.location == h_filebrowser || window.location == h_filebrowser+"/login?redirect=%2Ffiles%2F") window.location.reload();
}

autologin();
</script>
