const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    email: {
        type: String,
        required: true,
        unique: true,
        trim: true,
        lowercase: true
    },
    username: {
        type: String,
        required: true,
        trim: true
    },
    password: {
        type: String,
        required: true
    },
    location: {
        type: {
            type: String,
            enum: ['Point'],
            default: 'Point'
        },
        coordinates: {
            type: [Number],
            required: true
        }
    },
    isOnline: {
        type: Boolean,
        default: true
    },
    bio: {
        type: String,
        default: ''
    },
    profilePictureUrl: {
        type: String,
        default: ''
    },
    interests: {
        type: [String],
        default: []
    },
    gender: {
        type: String,
        default: ''
    },
    socialMediaLinks: {
        type: Map,
        of: String,
        default: {}
    },
    availabilityStatus: {
        type: String,
        default: 'Available'
    },
    birthday: {
        type: Date,
        default: null
    }
}, { timestamps: true });

userSchema.index({ location: '2dsphere' });

const User = mongoose.model('User', userSchema);

module.exports = User;
