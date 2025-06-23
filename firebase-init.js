// firebase-init.js
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.12.2/firebase-app.js";
import { getAuth } from "https://www.gstatic.com/firebasejs/10.12.2/firebase-auth.js";
import { getFirestore } from "https://www.gstatic.com/firebasejs/10.12.2/firebase-firestore.js";

const firebaseConfig = {
  apiKey: "AIzaSyCZpqSGl5sJrCMDfKIbwpLMO3pdvm6q218",
  authDomain: "medsreminder-cbc03.firebaseapp.com",
  projectId: "medsreminder-cbc03",
  storageBucket: "medsreminder-cbc03.appspot.com",
  messagingSenderId: "907426014383",
  appId: "1:907426014383:web:b798cb8806f3f606b3605a"
};

// Init Firebase
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

// Export for use elsewhere
export { auth, db };
