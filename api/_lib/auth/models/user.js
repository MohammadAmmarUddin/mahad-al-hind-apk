const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    phone: { type: String, default: '' },
    googleId: { type: String, default: null, sparse: true },
    avatar: { type: String, default: '' },
    provider: { type: String, enum: ['google', 'email', 'apple'], default: 'google' },
    emailVerified: { type: Boolean, default: false },
    role: { type: String, enum: ['user', 'admin', 'student', 'teacher'], default: 'user' },
    isSuspended: { type: Boolean, default: false },
    preferredLanguage: { type: String, default: 'en' },
    profession: [{ type: String }],
    lastLoginAt: { type: Date, default: null },
    refreshTokenVersion: { type: Number, default: 0 },
    refreshTokens: [{
      token: String,
      createdAt: { type: Date, default: Date.now },
      expiresAt: Date,
      userAgent: String,
    }],
  },
  { timestamps: true }
);

userSchema.index({ email: 1 }, { unique: true });
userSchema.index({ googleId: 1 }, { sparse: true });

userSchema.methods.toJSON = function () {
  const obj = this.toObject();
  delete obj.refreshTokens;
  delete obj.__v;
  return obj;
};

module.exports = mongoose.models.User || mongoose.model('User', userSchema);
