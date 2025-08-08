const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const User = require('./models/User');
const Invitation = require('./models/Invitation');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json({ limit: '50mb' }));
app.use(cors());

// MongoDB Connection
const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/whosnearme';
mongoose
  .connect(mongoUri)
  .then(() => console.log('MongoDB connected successfully'))
  .catch(err => console.error('MongoDB connection error:', err));

// Routes

// Register User
app.post('/api/register', async (req, res) => {
    const { username, password, latitude, longitude } = req.body;

    try {
        let user = await User.findOne({ username });
        if (user) {
            return res.status(400).json({ msg: 'User already exists' });
        }

        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        user = new User({
            username,
            password: hashedPassword,
            location: {
                type: 'Point',
                coordinates: [longitude, latitude]
            }
        });

        await user.save();
        res.status(201).json({ msg: 'User registered successfully' });

    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// Login User
app.post('/api/login', async (req, res) => {
    const { username, password } = req.body;

    try {
        const user = await User.findOne({ username });
        if (!user) {
            return res.status(400).json({ msg: 'Invalid Credentials' });
        }

        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(400).json({ msg: 'Invalid Credentials' });
        }

        res.json({ msg: 'Logged in successfully', userId: user._id });

    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// Update User Location
app.put('/api/location/:userId', async (req, res) => {
    const { latitude, longitude } = req.body;
    const { userId } = req.params;

    try {
        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({ msg: 'User not found' });
        }

        user.location.coordinates = [longitude, latitude];
        await user.save();

        res.json({ msg: 'Location updated successfully' });

    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// Get Nearby Users (online only, within radius)
app.get('/api/nearby/:userId', async (req, res) => {
    const { userId } = req.params;
    const radius = parseInt(req.query.radius, 10) || 5000; // default 5 km

    try {
        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({ msg: 'User not found' });
        }

        const nearbyUsers = await User.find({
            location: {
                $near: {
                    $geometry: {
                        type: 'Point',
                        coordinates: user.location.coordinates
                    },
                    $maxDistance: radius
                }
            },
            isOnline: true,
            _id: { $ne: userId } // Exclude the current user
        }).select('-password'); // Exclude password from results

        res.json(nearbyUsers);

    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// Get User Profile
app.get('/api/profile/:userId', async (req, res) => {
    const { userId } = req.params;
    try {
        const user = await User.findById(userId).select('-password');
        if (!user) {
            return res.status(404).json({ msg: 'User not found' });
        }
        res.json(user);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// Update User Profile
app.put('/api/profile/:userId', async (req, res) => {
    const { userId } = req.params;
    const { bio, profilePictureUrl, interests, gender, socialMediaLinks, availabilityStatus, birthday } = req.body;

    try {
        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({ msg: 'User not found' });
        }

        user.bio = bio !== undefined ? bio : user.bio;
        user.profilePictureUrl = profilePictureUrl !== undefined ? profilePictureUrl : user.profilePictureUrl;
        user.interests = interests !== undefined ? interests : user.interests;
        user.gender = gender !== undefined ? gender : user.gender;
        user.socialMediaLinks = socialMediaLinks !== undefined ? socialMediaLinks : user.socialMediaLinks;
        user.availabilityStatus = availabilityStatus !== undefined ? availabilityStatus : user.availabilityStatus;
        user.birthday = birthday !== undefined ? birthday : user.birthday;

        await user.save();
        res.json({ msg: 'Profile updated successfully', user });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// Send Invitation
app.post('/api/invite', async (req, res) => {
    const { senderId, receiverId, reason } = req.body;

    try {
        const invitation = new Invitation({
            sender: senderId,
            receiver: receiverId,
            reason
        });

        await invitation.save();
        res.status(201).json({ msg: 'Invitation sent successfully', invitation });

    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// Update Online Status
app.put('/api/status/:userId', async (req, res) => {
    const { userId } = req.params;
    const { isOnline } = req.body;

    try {
        const user = await User.findByIdAndUpdate(
            userId,
            { isOnline: Boolean(isOnline) },
            { new: true }
        );

        if (!user) {
            return res.status(404).json({ msg: 'User not found' });
        }

        res.json({ msg: 'Status updated successfully', isOnline: user.isOnline });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// Accept Invitation
app.put('/api/invite/:invitationId/accept', async (req, res) => {
    const { invitationId } = req.params;

    try {
        const invitation = await Invitation.findByIdAndUpdate(
            invitationId,
            { status: 'accepted' },
            { new: true }
        );

        if (!invitation) {
            return res.status(404).json({ msg: 'Invitation not found' });
        }

        res.json({ msg: 'Invitation accepted', invitation });

    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// Decline Invitation
app.put('/api/invite/:invitationId/decline', async (req, res) => {
    const { invitationId } = req.params;

    try {
        const invitation = await Invitation.findByIdAndUpdate(
            invitationId,
            { status: 'declined' },
            { new: true }
        );

        if (!invitation) {
            return res.status(404).json({ msg: 'Invitation not found' });
        }

        res.json({ msg: 'Invitation declined', invitation });

    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// Get Sent Invitations
app.get('/api/invitations/sent/:userId', async (req, res) => {
    const { userId } = req.params;

    try {
        const invitations = await Invitation.find({ sender: userId }).populate('receiver', 'username');
        res.json(invitations);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// Get Received Invitations
app.get('/api/invitations/received/:userId', async (req, res) => {
    const { userId } = req.params;

    try {
        const invitations = await Invitation.find({ receiver: userId }).populate('sender', 'username');
        res.json(invitations);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// Start the server
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
